require 'chef/provisioning/registry/helpers'

class Chef
  module Provisioning
    module Registry
      module DataHandler
        class ForSearch
          include Chef::Provisioning::Registry::Helpers

          def initialize(new_resource)
            registry_opts  = {}
            machine_opts   = {}
            transport_opts = {}
            merged_opts    = {}

            new_resource.instance_variables.each {
              |f|
              if /machine_options/.match(f.to_s)
                machine_opts[f.to_s[1..-1]] = new_resource.instance_variable_get(f)
              elsif /registry_options/.match(f.to_s)
                registry_opts[f.to_s[1..-1]] = new_resource.instance_variable_get(f)
              elsif /transport_options/.match(f.to_s)
                transport_opts[f.to_s[1..-1]] = new_resource.instance_variable_get(f)
              elsif /@name/.match(f.to_s)
                merged_opts['id'] = new_resource.instance_variable_get(f)
              end
            }

            @search_data    = merged_opts.empty?    ? {} : stringify_keys(merged_opts)
            @transport_data = transport_opts.empty? ? {} : stringify_keys(transport_opts)
            @registry_data  = registry_opts.empty?  ? {} : stringify_keys(registry_opts)
            @machine_data   = machine_opts.empty?   ? {} : stringify_keys(machine_opts)
          end

          attr_reader :registry_data, :machine_data, :transport_data, :search_data

          ##
          # Registry Options Resource
          # new_resource.registry_options
          def resource_registry_options
            registry_data['registry_options']
          end

          ##
          # Transport Options Resource
          # new_resource.transport_options
          def resource_transport_options
            transport_data['transport_options']
          end

          ##
          # Machine Options Resource
          # new_resource.machine_options
          def machine_options_registry_options
            machine_data['machine_options']['registry_options']
          end

          def machine_options_transport_options
            machine_data['machine_options']['transport_options']
          end

          ##
          # Merge Options, prefer direct resource over machine_options
          def merged_registry_options
            Chef::Mixin::DeepMerge.merge(resource_registry_options, machine_options_registry_options)
          end

          def merged_transport_options
            Chef::Mixin::DeepMerge.merge(resource_transport_options, machine_options_transport_options)
          end

          ##
          # Construct and Return Search Hash
          def search_hash
            search_data['registry_options']  = merged_registry_options
            search_data['transport_options'] = merged_transport_options if (merged_transport_options &&
                                                                            merged_transport_options.is_a?(Hash) &&
                                                                            !merged_transport_options.empty?)
            stringify_keys(search_data)
          end

        end
      end
    end
  end
end
