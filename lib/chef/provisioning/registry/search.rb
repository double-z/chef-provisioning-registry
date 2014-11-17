require 'chef/provisioning/registry/helpers'
require 'mac_address'

class Chef
  module Provisioning
    module Registry
      class Search
        include ::Chef::Provisioning::Registry::Helpers

        def initialize(registry_spec, cluster_path = false)
          @cluster_path = (@cluster_path || cluster_path) # || Chef::Resource::MachineRegistryPath.path)
          @registry_spec = registry_spec
          log_info "Search registry_spec #{registry_spec}"
          @given_transport_options = @registry_spec['machine_options'][:transport_options] rescue {}
          @given_registry_options = @registry_spec['registry_options'] rescue {}
          @given_machine_type = @given_registry_options['machine_types'] || @given_registry_options['machine_type'] rescue false
        end

        def given_registry_ip
          return @given_registry_ip if @given_registry_ip
          @given_registry_ip = false
          if  @given_registry_options && @given_registry_options['ip_address']
            @given_registry_ip = ip_is_valid?(@given_registry_options['ip_address'])
          end
          @given_registry_ip
        end

        def given_transport_ip
          return @given_transport_ip if @given_transport_ip
          @given_transport_ip = false
          if  @given_transport_options && @given_transport_options[:ip_address]
            @given_transport_ip = ip_is_valid?(@given_transport_options[:ip_address])
          end
          @given_transport_ip
        end

        def given_machine_type
          return @given_machine_type if @given_machine_type
          @given_machine_type = false
          if  @given_registry_options && (@given_registry_options['machine_type'] ||
                                          @given_registry_options['machine_types'])
            @given_machine_type = (@given_registry_options['machine_type'] ||
                                   @given_registry_options['machine_types'])
            error_message = "Machine Type Is An Array in Registry But Must Be Passed As A String"
            raise error_message unless @given_machine_type.kind_of?(String)
          end
          @given_machine_type
        end

        def search
          return false_or_value(@matched_hash) if @matched_hash
          @matched_hash = search_registry_options
          @matched_hash
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

        def registry_options_for(from_hash = {})
          current_registry_options(from_hash = {})
        end

        def self.registry_options_for(from_hash = {})
          Search.new.current_registry_options(from_hash)
        end

        def current_registry_options(from_hash = {})
          log_info "@current_registry_options #{@current_registry_options}" if @current_registry_options
          @current_registry_options ||= begin
            if @matched_hash && @matched_hash['registry_options']
              val = @matched_hash['registry_options']
              log_info "val = @matched_hash #{val}"
            elsif (from_hash)
              val = from_hash
              log_info "val = from_hash #{val}"
            else
              val = false
              log_info 'val = nil'
            end
            @current_registry_options = val
          end
          log_info "@current_registry_options #{@current_registry_options}" if @current_registry_options
          log_info "@current_registry_options are val #{val}" if !@current_registry_options
          return @current_registry_options || val
        end

        def allocate
          log_info "self #{self.inspect}"
        end

        def valid_arch_types
          vat = ["x86_64", "i386"]
          vat
        end

        def available_ip_file
          return false unless match_ip_address
          file = ::File.join(@cluster_path, "#{match_ip_address}.json")
          file_exists = ::File.exists?(file)
          return file_exists ? file : file_exists
        end

        def available_mac_file
          return false unless match_mac_address
          file = ::File.join(@cluster_path, "#{match_mac_address}.json")
          file_exists = ::File.exists?(file)
          return file_exists ? file : file_exists
        end

        def registry_files
          Array(Dir.glob(::File.join(@cluster_path, "*.json"))).sort
        end

        def match_ip_address
          return @match_ip_address if @match_ip_address
          transport_ip = ip_is_valid?(given_transport_ip)
          registry_ip = ip_is_valid?(given_registry_ip)
          if registry_ip && transport_ip
            ips_match = (registry_ip == transport_ip)
            raise("IP was given for Transport and Registry Options but do not match") unless ips_match
          end
          @match_ip_address = (registry_ip || transport_ip || false)
          @match_ip_address
        end

        def match_mac_address
          return @match_mac_address if @match_mac_address
          registry_mac = false
          if @given_registry_options && @given_registry_options['mac_address']
            registry_mac = mac_is_valid?(@given_registry_options['mac_address'])
          end
          @match_mac_address = registry_mac
          @match_mac_address
        end

        def ip_is_valid?(v_ip_address = false)
          valid_ip = false
          if (v_ip_address && !v_ip_address.nil? && !v_ip_address.empty?)
            valid_ip = (v_ip_address =~ Resolv::IPv4::Regex ||
                        v_ip_address =~ Resolv::IPv6::Regex)
            raise("Invalid IP #{v_ip_address} was passed to the Machine Registry") unless valid_ip
          end
          return valid_ip ? v_ip_address : valid_ip
        end

        def mac_is_valid?(v_mac_address = false)
          valid_mac = false
          if (v_mac_address && !v_mac_address.nil? && !v_mac_address.empty?)
            valid_mac = v_mac_address.valid_mac?
            raise("Invalid MAC #{v_mac_address} was passed to the Machine Registry") unless valid_mac
          end
          return valid_mac ? v_mac_address : valid_mac
        end

        def search_registry_options
          gots = false
          if available_ip_file
            gots = do_match(available_ip_file)
            log_info "available_ip_file match #{available_ip_file}" if gots.kind_of?(Hash)
          end
          if available_mac_file && !gots && !gots.kind_of?(Hash)
            gots = do_match(available_mac_file)
            log_info "available_mac_file match #{available_mac_file}" if gots.kind_of?(Hash)
          end
          unless gots && gots.kind_of?(Hash)
            registry_files.each do |available_file|
              gots = do_match(available_file)
              log_info "available_file match #{available_file}" if gots.kind_of?(Hash)
              break if gots.kind_of?(Hash)
            end
          end
          gots = false unless gots.kind_of?(Hash)
          rtv = gots ? ::JSON.parse(gots.to_json) : false
          return rtv
        end

        def do_match(available_file)
          will_work      = false
          not_gonna_work = false
          machine_type   = false
          r_m_h          = JSON.parse(File.read(available_file))

          # Loop Through Registered Machine Hash
          r_m_h.each_pair do |kk,vv|
            next if not_gonna_work
            log_info("KK = #{kk} and VV = #{vv}")
            if kk == "status"
              not_gonna_work = true if vv != "available"
            elsif kk == 'registry_options'
              log_info("has registry_options: #{vv}")
              vv.each do |k,v|
                if k == "machine_types"
                  log_info("machine_types: k = #{k} v=#{v} desired machine type = #{@given_machine_type}")
                  if @given_machine_type && !@given_machine_type.empty? &&
                      !v.empty? && v.include?(@given_machine_type)
                    log_info("will_work array #{v} includes #{@given_machine_type}")
                    machine_type = {"machine_type" => @given_machine_type}
                    will_work = true
                  else
                    log_info "arrnot_gonna_work k=#{k} v=#{v} sv=#{@given_machine_type}"
                    not_gonna_work = true if (@given_machine_type || !v.empty?)
                  end
                elsif @given_registry_options.has_key?(k)
                  if k == "memory"
                    log_info "memory k=#{k} v=#{v} @given_registry_options[k] #{@given_registry_options[k][0]} and #{@given_registry_options[k][1]}"
                    # will_work = true
                    if (@given_registry_options[k][0]..@given_registry_options[k][1]).include?(v)
                      log_info "INCLUDES Memory Range encompassing #{v}"
                      will_work = true
                    else
                      log_info "DOES NOT INCLUDE Memory Range encompassing #{v}"
                      not_gonna_work = true
                    end
                  elsif v == @given_registry_options[k] && !v.empty?
                    log_info("string will_work: #{v} == #{@given_registry_options[k]}")
                    will_work = true
                  else
                    puts "str not_gonna_work k=#{k} v=#{v} sv=#{@given_registry_options[k]}"
                    not_gonna_work = true unless (v.empty? ||
                                                  @given_registry_options[k].empty? ||
                                                  k == "password" )
                  end
                end
              end
            end
          end
          #
          # So we looped through an available machine and:
          # - we matched
          # - or we got nothin and move on to the next loop
          #
          if (will_work == true) && (not_gonna_work == false)
            log_info "matched file is #{available_file}"
            ro_ip  = "false"
            ro_mac = "false"
            tr_ip  = "false"
            matched_registry_file_id = r_m_h['id']
            r_m_h.delete_if {|key,value| !["registry_options", "machine_options"].include?(key) }

            if r_m_h['registry_options']
              r_m_h['registry_options'].each {|key,value| ro_ip = ip_is_valid?(value) if key == "ip_address"}
              r_m_h['registry_options'].each {|key,value| ro_mac = mac_is_valid?(value) if key == "mac_address"}
              r_m_h['registry_options'].delete_if {|key,value| key == "machine_types"}
              r_m_h['registry_options'].merge!(machine_type) if machine_type
              log_info "rmh is #{r_m_h['registry_options']}"
            end
            if r_m_h['machine_options'] && r_m_h['machine_options']['transport_options']
              r_m_h['machine_options']['transport_options'].each {|key,value| tr_ip = ip_is_valid?(value) if key == "ip_address"}
            end

            r_m_h['registry_options']  = {} unless (r_m_h['registry_options'] &&
                                                    r_m_h['registry_options'].is_a?(Hash))
            r_m_h['location']   = {} unless r_m_h['location']
            r_m_h['machine_options']   = {} unless r_m_h['machine_options']
            r_m_h['machine_options']['transport_options'] = {} unless (r_m_h['machine_options']['transport_options'] &&
                                                                       r_m_h['machine_options']['transport_options'].is_a?(Hash))

            use_ip = validate_matched_options_ip_addresses(tr_ip, ro_ip)

            r_m_h['registry_options']['ip_address'] = use_ip if use_ip
            r_m_h['machine_options']['transport_options']['ip_address'] = use_ip if use_ip
            r_m_h['machine_options']['transport_options']['host'] = use_ip if use_ip
            r_m_h['location']['matched_registry_file'] = available_file
            r_m_h['location']['matched_registry_file_id'] = matched_registry_file_id
            r_m_h['location']['matched_registry_file_at'] = Time.now

            log_info "r_m_h final is #{r_m_h}"

            if false_or_value(use_ip) || false_or_value(ro_mac)
              useip = false_or_value(use_ip)
              log_info "sanity_check_against_taken file: #{available_file} useip: #{useip} ro_mac: #{ro_mac}"
              sanity_check_against_taken(available_file, useip, ro_mac)
            end

            @registry_spec['registry_options'].delete('memory') if @registry_spec['registry_options']['memory']

            rmh_merged = Chef::Mixin::DeepMerge.merge(@registry_spec, r_m_h)

            return ::JSON.parse(rmh_merged.to_json)
          else
            log_info "did not matched file #{available_file}"
            return "false"
          end
        end

        def validate_matched_options_ip_addresses(moip, roip)
          mo_ip = false_or_value(moip)
          ro_ip = false_or_value(roip)
          r_i_p = false

          log_info "mo_ip is #{mo_ip.to_s}"
          if mo_ip && ro_ip
            raise "validate_matched_options_ip_addresses #{mo_ip} and #{ro_ip} do not match" if mo_ip != ro_ip
            r_i_p = ro_ip
          elsif (mo_ip || ro_ip)
            r_i_p = mo_ip || ro_ip
            log_info "r_i_p is #{r_i_p}"
          end
          if match_ip_address
            match_ip_error = "match_ip_address #{match_ip_address} does not match registry ip_address #{r_i_p}"
            raise match_ip_error if (r_i_p && (match_ip_address != r_i_p))
            use_ip = match_ip_address
          else
            use_ip = r_i_p
          end
          use_ip
        end


        def sanity_check_against_taken(matched_file, mip, mmac)
          new_match_ip  = false_or_value(mip)
          new_match_mac = false_or_value(mmac)

          Array(Dir.glob(registry_files)).sort.each do |f|
            next if f == matched_file
            log_info "comparing #{matched_file} against #{f}"
            error_out = false
            existing_tr_ip = false
            existing_ro_ip = false
            existing_ro_mac = false

            r_m_h = JSON.parse(File.read(f))
            r_m_h.each_pair do |kk,vv|
              if kk == 'ip_address'
                existing_tr_ip = ip_is_valid?(vv)
                log_info "existing_mo_ip is #{existing_tr_ip}"
              elsif kk == 'registry_options'
                vv.each do |k,v|
                  case k
                  when 'ip_address'
                    existing_ro_ip = ip_is_valid?(v)
                    log_info "existing_ro_ip is #{existing_ro_ip}"
                  when 'mac_address'
                    existing_ro_mac = mac_is_valid?(v)
                    log_info "existing_ro_mac is #{existing_ro_mac}"
                  end
                end
              end
            end

            error_message = 'We Matched'
            if ((new_match_ip && (existing_tr_ip || existing_ro_ip)) &&
                (new_match_ip == existing_ro_ip || new_match_ip == existing_tr_ip))
              error_out = true
              error_message << ' IP,'
            end
            if ((new_match_mac && existing_ro_mac) && (new_match_mac.to_mac == existing_ro_mac.to_mac))
              error_out = true
              error_message << ' MAC ADDRESS,'
            end
            error_message << ' but they already exist.'
            error_message << ' Aborting to avoid inconsistencies.'
            raise error_message if error_out
            # log_info error_message if error_out
            log_info("no match on existing for #{f}")
          end

        end

      end
    end
  end
end
