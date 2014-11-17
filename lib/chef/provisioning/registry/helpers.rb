class Chef
  module Provisioning
    module Registry
      module Helpers

        ##
        # Custom Logging Via ENV VARS
        def log_info(str = false)
          if str.kind_of?(String) && ENV['METAL_SSH_LOGGING_ENABLE']
            if str.empty?
              return
            else
              log_debug(str)
            end
          else
            return
          end
        end

        def log_debug(str = false)
          if str.kind_of?(String)
            if str.empty?
              return
            else
              if ENV['METAL_SSH_LOGGING_ENABLE']
                log_ts(str)
              else
                Chef::Log.debug("======================================>")
                Chef::Log.debug(str)
                Chef::Log.debug("======================================>")
              end
            end
          else
            return
          end
        end

        def log_ts(str)
          put_val = []
          put_val << ""
          put_val << ("=================== BEGIN LOG ENTRY ====================>")
          put_val << str
          put_val << ("===================  END LOG ENTRY  ====================>")
          put_val << ""
          puts put_val
        end

        ##
        # Hash Manipulation
        def symbolize_keys(hash)
          if hash.is_a?(Hash)
            hash.inject({}){|result, (key, value)|
              new_key   = case key
              when String
                key.to_sym
              else
                key
              end

              new_value = case value
              when Hash
                symbolize_keys(value)
              when String
                value
              else
                value
              end

              result[new_key] = new_value
              result
            }
          end
        end

        def stringify_keys(hash)
          if hash.is_a?(Hash)
            hash.inject({}){|result, (key, value)|
              new_key   = case key
              when Symbol
                key.to_s
              else
                key
              end

              new_value = case value
              when Hash
                stringify_keys(value)
              when String
                value
              else
                value
              end

              result[new_key] = new_value
              result
            }
          end
        end

        def strip_hash_nil(val)
          if val
            vvv = case val
            when Hash
              cleaned_val = val.delete_if { |kk,vv| vv.nil? || vv.empty? }
              cleaned_val.each do |k,v|
                case v
                when Hash
                  strip_hash_nil(v)
                when Array
                  v.flatten!
                  v.uniq!
                end
              end
            end
            vvv
          end
        end

        def false_or_value(v)
          case v
          when "false"
            false
          when false
            false
          else
            v
          end
        end

        def valid_ip?(given_ip)
          if ip_is_valid?(given_ip)
            true
          else
            false
          end
        end

        def ip_is_valid?(given_ip)
          valid_ip = ( given_ip =~ Resolv::IPv4::Regex || given_ip =~ Resolv::IPv6::Regex )
          valid_ip
        end

        def valid_registry_options_keys
          vrok = %w{
            ssh_cluster_path
            machine_types
            mac_address
            ip_address
            subnet
            hostname
            domain
            fqdn
            memory
            cpu_count
            cpu_type
            arch
          }
          vrok
        end

        def valid_ssh_options
          vso = [
            :auth_methods,
            :bind_address,
            :compression,
            :compression_level,
            :config,
            :encryption,
            :forward_agent,
            :hmac,
            :host_key,
            :keepalive,
            :keepalive_interval,
            :kex,
            :keys,
            :key_data,
            :languages,
            :logger,
            :paranoid,
            :port,
            :proxy,
            :rekey_blocks_limit,
            :rekey_limit,
            :rekey_packet_limit,
            :timeout,
            :verbose,
            :global_known_hosts_file,
            :user_known_hosts_file,
            :host_key_alias,
            :host_name,
            :user,
            :properties,
            :passphrase,
            :keys_only,
            :max_pkt_size,
            :max_win_size,
            :send_env,
            :use_agent
          ]
          vso
        end

      end
    end
  end
end
