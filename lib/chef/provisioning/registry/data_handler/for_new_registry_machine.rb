require 'resolv'
require 'mac_address'
require 'chef/provisioning/registry/helpers'

class Chef
  module Provisioning
    module Registry
      module DataHandler
        class ForNewRegistryMachine
          include Chef::Provisioning::Registry::Helpers

          def initialize(given_hash)
            @given_options = stringify_keys(given_hash)
            @registry_options = given_options['registry_options']
            @transport_options = given_options['machine_options']['transport_options'] rescue {}
          end

          attr_reader :registry_options, :transport_options, :given_options

          def new_hash
            get_specs_from_remote_machine if retrieve_specs_from_target?
            trfc = {}
            trfc['id']               = use_id_value
            trfc['status']           = given_options['status']
            trfc['registry_options'] = registry_options_for
            trfc['machine_options']  = machine_options_for
            trfc
          end

          def use_id_value
            if get_mac_address && name_is_mac?
              return get_mac_address.to_mac
            else
              val = given_options['name'].gsub('.','-')
              return val
            end
          end

          def registry_options_for
            tsf = {}
            tsf['registry_options'] = {}
            tsf['registry_options']['ip_address']    = registry_options['ip_address'] if registry_options['ip_address']
            tsf['registry_options']['machine_types'] = Array(registry_options['machine_types'])
            tsf['registry_options']['mac_address']   = get_mac_address if get_mac_address
            tsf['registry_options']['subnet']        = get_subnet if get_subnet
            tsf['registry_options']['domain']        = registry_options['domain'] if get_domain
            tsf['registry_options']['fqdn']          = registry_options['fqdn'] if get_fqdn
            tsf['registry_options']['memory']        = get_memory if get_memory
            tsf['registry_options']['cpu_count']     = get_cpu_count if get_cpu_count
            tsf['registry_options']['cpu_type']      = registry_options['cpu_type'] if registry_options['cpu_type']
            tsf['registry_options']['arch']          = get_arch if get_arch
            tsf['registry_options']
          end

          def machine_options_for
            trfc = {}
            trfc[:transport_options]  = {}
            if registry_options
              trfc[:transport_options]['ip_address'] = registry_options['ip_address'] if registry_options['ip_address']
            end
            if transport_options
              trfc[:transport_options]['hostname'] = transport_options['hostname'] if transport_options['hostname']
              if transport_options['ssh_options']
                trfc[:transport_options]['ssh_options'] = {}
                trfc[:transport_options]['username'] = transport_options['ssh_options']['user'] if transport_options['ssh_options']['user']
                trfc[:transport_options]['ssh_options']['user'] = transport_options['ssh_options']['user'] if transport_options['ssh_options']['user']
                trfc[:transport_options]['ssh_options']['password'] = transport_options['ssh_options']['password'] if transport_options['ssh_options']['password']
                trfc[:transport_options]['ssh_options']['keys'] = get_ssh_keys if get_ssh_keys
              end
            end
            trfc
          end

          def get_specs_from_remote_machine
            if retrieve_specs_from_target?
              return @registry_options_from_machine if @registry_options_from_machine
              log_info("TARGET SPECS FOR #{registry_options['ip_address']} EXIST = #{@registry_options_from_machine}") if @registry_options_from_machine

              ssh_options = {}
              if transport_options['ssh_options']
                ssh_options = ssh_options.merge!({ :password => transport_options['ssh_options']['password'] }) if transport_options['ssh_options']['password']
                ssh_options = ssh_options.merge!({ :keys => get_ssh_keys }) if get_ssh_keys
              end

              Net::SSH.start(registry_options['ip_address'], transport_options['username'], ssh_options) do |ssh|
                stdout = {}
                sshcmd = "wget #{metal_spec_sh_source} -q -O - | bash"
                ssh.exec!(sshcmd) do |channel, stream, data|
                  d = data.split("=")
                  merge_val = { d.first.chomp => d.last.chomp }
                  stdout.merge!(merge_val)
                end
                @registry_options_from_machine = ::JSON.parse(stdout.to_json)
              end
              log_info("TARGET SPECS RETRIEVED = #{@registry_options_from_machine}")
              @registry_options_from_machine
            else
              @registry_options_from_machine = {}
              @registry_options_from_machine
            end
          end

          def updated_ssh_hash(existing_transport_options, machine_transport_options)
            return @updated_ssh_hash_for if @updated_ssh_hash_for
            eso = stringify_keys(existing_transport_options)
            mso = stringify_keys(machine_transport_options)
            @updated_ssh_hash_for = false
            new_hash = {}
            new_keys = Array(eso['keys']).concat( Array(mso['keys']) ) || false
            log_info("new_keys = #{new_keys}")
            new_hash = Chef::Mixin::DeepMerge.merge(new_hash, { 'keys' => new_keys }) if new_keys
            new_hash = Chef::Mixin::DeepMerge.merge(new_hash, { 'password' => mso['password'] }) if mso['password']
            sofr = Chef::Mixin::DeepMerge.merge(eso, mso)
            _sofr = sofr
            @updated_ssh_hash_for = _sofr
            @updated_ssh_hash_for = Chef::Mixin::DeepMerge.merge(sofr, new_hash) unless new_hash.empty?
            return @updated_ssh_hash_for
          end


          ##
          #
          # This Section Is Responsible For Determining the Value(s) desired for
          #    Each Individual Attribute Value
          #
          #
          def metal_spec_sh_source
            registry_options['metal_spec_script'] || "http://bit.ly/metal_spec_sh_latest"
          end

          def get_cpu_count
            return @get_cpu_count_value if @get_cpu_count_value
            @get_cpu_count_value = (get_specs_from_remote_machine['cpu_count'] ||
                                    registry_options['cpu_count'] ||
                                    false)
            @get_cpu_count_value
          end

          def get_memory
            return @get_memory_value if @get_memory_value
            @get_memory_value = (get_specs_from_remote_machine['memory'] ||
                                 registry_options['memory'] ||
                                 false)
            # @get_memory_value = registry_options['memory']
            @get_memory_value
          end

          def get_mac_address
            # return @get_mac_address_value if @get_mac_address_value
            if retrieve_specs_from_target?
              get_mac_address_value = get_specs_from_remote_machine['mac_address']
              if registry_options['mac_address']
                values_match = (get_mac_address_value.to_mac ==
                                registry_options['mac_address'].to_mac)
                raise "Retrieved Remote and Given MAC Addr Do Not Match" unless values_match
              end
            else
              get_mac_address_value = registry_options['mac_address'] || false
            end
            get_mac_address_value
          end

          def get_subnet
            return @get_subnet_value if @get_subnet_value
            @get_subnet_value = (get_specs_from_remote_machine['subnet'] ||
                                 registry_options['subnet'] ||
                                 false)
            @get_subnet_value
          end

          def get_fqdn
            registry_options['fqdn'] || false # || @registry_options['fqdn'] rescue false
          end

          def get_domain
            registry_options['domain'] || false # || @registry_options['domain'] rescue false
          end

          def get_arch
            return @get_arch_value if @get_arch_value
            @get_arch_value = (get_specs_from_remote_machine['arch'] ||
                               registry_options['arch'] ||
                               false)
            @get_arch_value
          end

          def get_ssh_keys
            if (transport_options &&
                transport_options['ssh_options'] &&
                transport_options['ssh_options']['keys'])
              key_array = Array(transport_options['ssh_options']['keys'])
              if key_array.empty?
                return false
              else
                return key_array.flatten.compact.uniq
              end
            else
              false
            end
          end

          def ssh_option_pass_or_key
            if transport_options['keys']
              return get_ssh_keys
            elsif transport_options['password']
              return transport_options['password']
            else
              false
            end
          end

          def retrieve_specs_from_target?
            log_info("given_options['retrieve_specs'] = #{given_options['retrieve_specs']}")

            do_retrieve_specs = (given_options['retrieve_specs'] || ENV['METAL_SSH_RETRIEVE_SPECS'])
            if (name_not_mac? && do_retrieve_specs && enough_credentials_to_connect? && can_ssh_to_target?)
              # if enough_credentials_to_connect?
              log_info("retrieve_specs_from_target? = true")
              true
            else
              log_info("retrieve_specs_from_target? = false")
              false
            end
          end

          def name_not_mac?
            return @ismac if @ismac
            tf = (given_options['mac_address'] &&
                  (given_options['mac_address'].to_mac == given_options['name']))
            if tf
              @ismac = false
            else
              @ismac = true
            end
            @ismac
          end

          def name_is_mac?
            tf = (given_options['mac_address'] &&
                  (given_options['mac_address'].to_mac == given_options['name']))
            tf
          end

          def can_ssh_to_target?
            # test = ChefMetal::Transport::SSH.new(@host, @username, @ssh_options_for_transport, @options, config)
            # test.available?
            # if
            # false
            true
          end

          def enough_credentials_to_connect?
            log_info "enough_credentials_to_connect? transport_options #{transport_options}"
            if (transport_options['username'] &&
                transport_options['ssh_options'] &&
                (transport_options['ssh_options']['password'] || transport_options['ssh_options']['keys']))
              log_info("enough_credentials_to_connect? = true")
              true
            else
              log_info("enough_credentials_to_connect? = false")
              false
            end
          end

        end
      end
    end
  end
end
