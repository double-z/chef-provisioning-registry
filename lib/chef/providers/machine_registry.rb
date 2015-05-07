require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'chef/provider/machine'
require 'openssl'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/chef_machine_spec'
require 'chef/provisioning/registry/chef_registry_spec'
require 'chef/provisioning/registry'
require 'chef/provisioning/registry/helpers'
require 'chef/provisioning/registry/search'
require 'chef/provisioning/registry/data_handler'
require 'chef/provisioning/registry/data_handler/for_search'

class Chef
  class Provider
    class MachineRegistry < Chef::Provider::LWRPBase
      include Chef::Provisioning::Registry
      include Chef::Provisioning::Registry::Helpers

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      use_inline_resources

      def whyrun_supported?
        true
      end

      action :allocate do
        existing_registry_data = false

        if search_registry?
          log_info "search_registry = #{search_registry?}"
          match_machine = Chef::Provisioning::Registry::Search.new(search_params, registry_path)
          existing_registry_data = match_machine.search(new_resource.registry_source)
          if existing_registry_data
            matched_machine = stringify_keys(existing_registry_data.dup)
            log_info "Provider::action_allocate::search_match matched_machine = #{matched_machine}"
            registry_spec.machine_options   = machine_options_for(matched_machine)
            registry_spec.registry_options  = registry_options_for(matched_machine)
            registry_spec.location          = location_for(matched_machine)
            registry_spec.registry_source   = new_resource.registry_source
            registry_spec.status            = 'allocated'
            log_info "Provider::action_allocate::search results in registry_spec = #{registry_spec.registry_data}"
          end
        elsif registry_machine_exists?
          existing_registry_data = registry_spec.registry_data
          log_info "Provider::action_allocate::exists existing_registry_data = #{existing_registry_data}"
        end

        if current_driver && current_driver.driver_url != new_driver.driver_url
          raise "Cannot move '#{machine_spec.name}' from #{current_driver.driver_url} to #{new_driver.driver_url}: machine moving is not supported.  Destroy and recreate."
        end

        if !new_driver
          raise "Driver not specified for machine #{machine_spec.name}"
        end

        log_info "new_machine_options #{new_machine_options}"

        new_driver.allocate_machine(action_handler, machine_spec, new_machine_options)
        machine_spec.save(action_handler)
        registry_spec.save(action_handler) if existing_registry_data
        log_info "Provider::action_allocate - saved registry_spec = #{existing_registry_data}"
      end

      action :ready do
        action_allocate
        machine = current_driver.ready_machine(action_handler, machine_spec, current_machine_options)

        machine_spec.save(action_handler)
        if registry_machine_exists?
          _machine_transport              = machine.transport
          registry_spec.transport_options = new_transport_options(_machine_transport.dup)
          registry_spec.save(action_handler)
        end
        machine
      end

      action :setup do
        machine = action_ready
        begin
          machine.setup_convergence(action_handler)
          machine_spec.save(action_handler)
          upload_files(machine)
        ensure
          machine.disconnect
        end
      end

      action :converge do
        action_allocate
        machine = action_ready
        begin
          machine.setup_convergence(action_handler)
          machine_spec.save(action_handler)
          upload_files(machine)
          if new_resource.converge || (new_resource.converge.nil? && resource_updated?) ||
              !machine_spec.node['automatic'] || machine_spec.node['automatic'].size == 0
            machine.converge(action_handler)
          end
        ensure
          machine.disconnect
        end
      end

      action :converge_only do
        machine = run_context.chef_provisioning.connect_to_machine(machine_spec, current_machine_options)
        begin
          machine.converge(action_handler)
        ensure
          machine.disconnect
        end
      end

      action :stop do
        if current_driver
          current_driver.stop_machine(action_handler, machine_spec, current_machine_options)
        end
      end

      action :destroy do
        if current_driver
          current_driver.destroy_machine(action_handler, machine_spec, current_machine_options)
        end
        registry_spec.delete(action_handler)
      end

      attr_reader :machine_spec, :registry_spec

      def new_driver
        if @use_new_driver
          return @use_new_driver
        else
          @use_new_driver ||= begin
            if registry_spec.get_status
              run_context.chef_provisioning.driver_for(new_resource.registry_driver)
            else
              run_context.chef_provisioning.driver_for(new_resource.driver)
            end
          end
        end
      end

      def current_driver
        if @use_current_driver
          return @use_current_driver
        else
          @use_current_driver ||= begin
            if registry_machine_exists? && registry_spec.driver_url
              run_context.chef_provisioning.driver_for(registry_spec.driver_url)
            else
              if machine_spec.driver_url
                run_context.chef_provisioning.driver_for(machine_spec.driver_url)
              end
            end
          end
        end
      end

      def from_image_spec
        @from_image_spec ||= begin
          if new_resource.from_image
            Chef::Provisioning::ChefImageSpec.get(new_resource.from_image, new_resource.chef_server)
          else
            nil
          end
        end
      end

      def new_machine_options
        machine_options(new_driver)
      end

      def current_machine_options
        machine_options(current_driver)
      end

      def machine_options(driver)
        configs = []

        if from_image_spec && from_image_spec.machine_options
          configs << from_image_spec.machine_options
        end

        configs << {
          :convergence_options =>
          [ :chef_server,
            :allow_overwrite_keys,
            :source_key, :source_key_path, :source_key_pass_phrase,
            :private_key_options,
            :ohai_hints,
            :public_key_path, :public_key_format,
            :admin, :validator
          ].inject({}) do |result, key|
            result[key] = new_resource.send(key) if new_resource.send(key)
            result
          end
        }

        if registry_spec.get_status && registry_spec.machine_options
          configs << registry_spec.machine_options
        end

        log_info "registry_spec.machine_options #{registry_spec.machine_options}"

        configs << new_resource.machine_options if new_resource.machine_options
        configs << driver.config[:machine_options] if driver.config[:machine_options]
        Cheffish::MergedConfig.new(*configs)
      end

      def load_current_resource
        node_driver = Chef::Provider::ChefNode.new(new_resource, run_context)
        node_driver.load_current_resource
        json = node_driver.new_json
        json['normal']['chef_provisioning'] = node_driver.current_json['normal']['chef_provisioning']
        @machine_spec = Chef::Provisioning::ChefMachineSpec.new(json, new_resource.chef_server)
        @registry_spec = Chef::Provisioning::Registry::ChefRegistrySpec.get_or_empty(new_resource, new_resource.chef_server)
      end

      def self.upload_files(action_handler, machine, files)
        if files
          files.each_pair do |remote_file, local|
            if local.is_a?(Hash)
              if local[:local_path]
                machine.upload_file(action_handler, local[:local_path], remote_file)
              else
                machine.write_file(action_handler, remote_file, local[:content])
              end
            else
              machine.upload_file(action_handler, local, remote_file)
            end
          end
        end
      end

      def search_registry?
        tf = (new_resource.use_registry &&
              !registry_machine_exists? &&
              !(current_driver && current_driver.driver_url) &&
              !registry_spec.get_status &&
              search_params['registry_options'])
        tf
      end

      def search_params
        if @search_params
          return @search_params
        else
          @search_params ||= begin
            dhfs = DataHandler::ForSearch.new(new_resource)
            search_out = dhfs.search_hash
            ret_val = (search_out && search_out.is_a?(Hash) && !search_out.empty?) ? search_out : {}
            ret_val
          end
        end
      end

      def registry_path
        if ENV['REGISTRY_APP_ROOT']
          ::File.join(ENV['REGISTRY_APP_ROOT'], ".chef/provisioning/registry")
        else
          new_resource.registry_path
        end
      end

      def registry_machine_exists?
        ::File.exists?(registry_machine_file_path)
      end

      def registry_machine_file_path
        ::File.join(registry_path, "#{new_resource.name}.json")
      end

      def registry_options_for(matched_machine)
        matched_machine['registry_options']
      end

      def location_for(matched_machine)
        registry_driver = run_context.chef_provisioning.driver_for(new_resource.registry_driver)
        log_info "run_context.chef_provisioning.driver_for(new_resource.registry_driver) #{registry_driver.config.inspect}"
        use_location_for = {}
        use_location_for['registry_machine_path']    = registry_machine_file_path
        use_location_for['registry_driver']          = new_resource.registry_driver
        use_location_for['driver_url']               = registry_driver.driver_url
        use_location_for['matched_registry_file']    = matched_machine['location']['matched_registry_file']
        use_location_for['matched_registry_file_id'] = matched_machine['location']['matched_registry_file_id']
        use_location_for['matched_registry_file_at'] = matched_machine['location']['matched_registry_file_at'].to_s
        use_location_for
      end

      def machine_options_for(matched_machine)
        use_machine_options_for = {}
        if matched_machine['machine_options'] && (matched_machine['machine_options']['transport_options'] ||
                                                  matched_machine['machine_options'][:transport_options])
          use_machine_options_for[:transport_options] = (matched_machine['machine_options']['transport_options'] ||
                                                         matched_machine['machine_options'][:transport_options])
        end
        use_machine_options_for
      end

      def new_transport_options(transport_options)
        updated_transport_options(update_transport_options(transport_options))
      end

      def updated_transport_options(val)
        new_hash = {}
        val.each do |k,v|
          new_hash[k.to_s[1..-1]] = v
        end
        new_hash
      end

      def update_transport_options(transport_options)
        update_transport_options = {}
        Array(transport_options.instance_variables).each {
          |a| update_transport_options[a.to_s] = transport_options.instance_variable_get(a) unless a.to_s == "@config"
        }
        update_transport_options
      end

      private

      def upload_files(machine)
        Machine.upload_files(action_handler, machine, new_resource.files)
      end

    end
  end
end
