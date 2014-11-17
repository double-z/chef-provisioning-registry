#
# Specification for a registry. Sufficient information to find and contact it
# after it has been set up.
#
class Chef
  module Provisioning
    module Registry
      class RegistrySpec

        def initialize(registry_data)
          @registry_data = registry_data
        end

        attr_reader :registry_data

        def delete_convergence_options
          if machine_options['convergence_options']
            machine_options.delete('convergence_options')
          elsif machine_options[:convergence_options]
            machine_options.delete(:convergence_options)
          end
        end

        # URL to the driver.  Convenience for location['driver_url']
        def driver_url
          registry_data['location'] ? registry_data['location']['driver_url'] : nil
        end

        def driver_url=(value)
          registry_data['location'] ||= {}
          registry_data['location']['driver_url'] = value
        end

        #
        # Globally unique identifier for this registry. Does not depend on the registry's
        # location or existence.
        #
        def id
          # registry_data['name'] || "web"
        end

        def location
          registry_data['location']
        end

        #
        # Set the location for this registry.
        #
        def location=(value)
          registry_data['location'] = value
        end

        def machine_options
          registry_data['machine_options']
        end

        def machine_options=(value)
          registry_data['machine_options'] = value if value
        end

        def matched_file
          registry_data['location']['matched_file']
        end

        def matched_file=(value)
          registry_data['location']['matched_file'] = value if value
        end

        def matched_file_at
          registry_data['location']['matched_file_at']
        end

        def matched_file_at=(value)
          registry_data['location']['matched_file_at'] = value if value
        end

        #
        # Name of the registry. Corresponds to the name in "registry 'name' do" ...
        #
        def name
          registry_data['id'] #|| "web"
        end

        def registry_file
          registry_data['location'] ||= {}
          registry_data['location']['registry_file']
        end

        def registry_file=(value)
          registry_data['location'] ||= {}
          registry_data['location']['registry_file'] = value if value
        end

        def registry_machine_path
          registry_data['location'] ||= {}
          registry_data['location']['registry_machine_path']
        end

        def registry_machine_path=(value)
          registry_data['location'] ||= {}
          registry_data['location']['registry_machine_path'] = value if value
        end

        def registry_options
          registry_data['registry_options']
        end

        def registry_options=(value)
          registry_data['registry_options'] = value
        end

        def registry_options_ip=(ip)
          registry_data['registry_options']["ip_address"] = ip if ip
        end

        #
        # Save this registry_data to the server.  If you have significant information that
        # could be lost, you should do this as quickly as possible.  registry_data will be
        # saved automatically for you after allocate_registry and ready_registry.
        #
        def save(action_handler)
          raise "save unimplemented"
        end

        def status
          registry_data['status']
        end

        def status=(value)
          registry_data['status'] = value
        end

        def transport_options
          registry_data['machine_options'][:transport_options]
        end

        def transport_options=(value)
          registry_data['machine_options'][:transport_options] = value if value rescue false
        end

      end
    end
  end
end
