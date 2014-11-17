require 'chef/provisioning/registry/helpers'

class Chef
  module Provisioning
    module Registry
      module DataHandler
        class ForApi
          include Chef::Provisioning::Registry::Helpers

          def initialize(payload, registry_path)
            # datafile = params[:data]
            # payload = datafile[:tempfile].read
            d = []
            d << payload.split("\n")
            api_options = {}
            api_options['machine_types'] = []
            key_value = false
            d.each do |v|
              v.each do |a|
                b = a.split("====")
                if (b.first.chomp == 'machine_types') || (b.first.chomp == 'machine_type')
                  api_options[b.first.chomp] = Array(b.last.chomp)
                elsif b.first.chomp == 'private_key'
                  key_value = "-----BEGIN RSA PRIVATE KEY-----\n"
                  b.last.split(' ', -1).each do |lv|
                    key_value += "#{lv.to_s}\n"
                  end
                  key_value += "-----END RSA PRIVATE KEY-----\n"
                else
                  api_options[b.first.chomp] = b.last.chomp
                end
              end
            end

            @api_options_id = api_options['ip_address'].gsub('.','-')
            @registry_path = registry_path
            @ssh_key_value = key_value
            machine_options_for(api_options.dup)
            @registry_options = api_options.dup
          end

          attr_reader :registry_options, :registry_path, :ssh_key_value, :api_options_id

          def filename
            ::File.join(registry_path, "#{api_options_id}.json")
          end

          def keyname
            if ssh_key_value
              ::File.join(registry_path, "#{api_options_id}.pem")
            else
              false
            end
          end

          def machine_options_for(_api_options = false)
            if @machine_options_for
              return @machine_options_for
            else
              @machine_options_for ||= begin
                api_options = _api_options.dup
                machine_options = {}
                machine_options['transport_options'] = {}
                machine_options['transport_options']['ssh_options'] = {}
                machine_options['transport_options']['host'] = api_options['ip_address']
                machine_options['transport_options']['ip_address'] = api_options['ip_address']
                machine_options['transport_options']['ssh_options']['user'] = api_options['ssh_user']
                machine_options['transport_options']['ssh_options']['password'] = api_options['ssh_pass'] if api_options['ssh_pass']
                machine_options['transport_options']['ssh_options']['keys'] = [keyname] if keyname
                machine_options
              end
            end
          end

          ##
          # Registry Options Resource
          # new_resource.registry_options
          def registry_options_for
            registry_options.delete_if {|k,v| (k == 'ssh_user' || k == 'ssh_pass') }
            registry_options
          end

          def location_for
            location = {}
            location['registry_machine_path'] = filename
            location
          end

          ##
          # Construct and Return Search Hash
          def api_hash
            api_hash ||= {}
            api_hash['id']               = api_options_id
            api_hash['status']           = "available"
            api_hash['location']         = location_for
            api_hash['registry_options'] = registry_options_for
            api_hash['machine_options']  = machine_options_for if (machine_options_for &&
                                                                     machine_options_for.is_a?(Hash) &&
                                                                     !machine_options_for.empty?)
            stringify_keys(api_hash)
          end

        end
      end
    end
  end
end
