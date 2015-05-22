require 'json'
require 'net/ssh'
require 'resolv'
require 'mac_address'
require 'chef/provider/lwrp_base'
require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/provider/machine'
require 'chef/provisioning/chef_provider_action_handler'
require 'chef/provisioning/add_prefix_action_handler'
require 'chef/provisioning/machine_spec'
require 'chef/provisioning/chef_managed_entry_store'
#require 'chef/provisioning/chef_machine_spec'
require 'chef/provisioning/registry/helpers'
require 'chef/provisioning/registry/chef_registry_spec'
require 'chef/provisioning/registry/data_handler/for_new_registry_machine'

class Chef
  class Provider
    class RegistryMachine < Chef::Provider::LWRPBase
      include ::Chef::Provisioning::Registry::Helpers

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      use_inline_resources

      def whyrun_supported?
        true
      end

      action :new_available do
        unless ::File.exists?(registry_machine_file_path)
          ensure_directories
          log_info "data_for_new_available #{data_for_new_available}"
          registry_data = Chef::Provisioning::Registry::DataHandler::ForNewRegistryMachine.new(data_for_new_available)
          file_action(:create, registry_data)
        end
      end

      # action :allocate do
      #   ensure_directories
      #   data_from_resource
      #   # file_action(:create_if_missing)
      #   action_update
      # end

      # action :from_api do
      #   api_data = Chef::Provisioning::Registry::DataHandler.FromApi.new(trfc)
      # end

      # action :update do
      #   ensure_directories
      #   data_from_resource
      #   # file_action(:create_if_missing)
      #   action_update
      # end

      # action :delete do
      #   ensure_directories
      #   file_action(:delete)
      # end

      # action :deallocate do
      #   #
      #   ensure_directories
      #   data_from_resource
      #   # file_action(:create_if_missing)
      #   action_update
      # end

      def load_current_resource
        @current_resource = Chef::Resource::RegistryMachine.new(@new_resource.name)
      end

      ##
      #
      # This Is Responsible for Handling Action Delegation
      #
      def file_action(do_action, registry_data)
        file_hash = registry_data.new_hash
        chef_server = Cheffish.default_chef_server
        log_info "file_hash New #{file_hash}"
        registry_spec = Chef::Provisioning::Registry::ChefRegistrySpec.new(file_hash, chef_server)
        registry_spec.registry_machine_path = registry_machine_file_path
        # registry_spec.save(action_handler)          if (save_to_data_bag? && new_resource.save_to_file)
        # registry_spec.save_data_bag(action_handler) if (save_to_data_bag? && !new_resource.save_to_file)
        registry_spec.save_file(action_handler)   #  if (!save_to_data_bag? && new_resource.save_to_file)
        log_info "Registry Spec New #{registry_spec.registry_data}"
      end

      def data_for_existing
        trfc = {}
        trfc['name']               = new_resource.name
        trfc['status']             = value_for_file_name
        trfc['save_to_data_bag']   = save_to_data_bag?
        trfc['save_to_file']       = save_to_file?
        trfc['registry_spec_hash'] = new_resource.registry_spec_hash
        log_info("trfc = #{trfc}")
        @registry_data = Chef::Provisioning::Registry::DataHandler.new(trfc)
        @registry_data
      end


      def data_for_new_available
        trfc = {}
        trfc['name']                     = value_for_file_name
        trfc['status']                   = "available"
        trfc['retrieve_specs']           = do_retrieve_specs?
        trfc['ignore_retrieve_failures'] = new_resource.ignore_retrieve_failures
        trfc['metal_spec_script']        = new_resource.metal_spec_script

        # trfc['location_hash']          = new_resource.location_hash || {}
        # trfc['registry_options_hash']  = new_resource.registry_options_hash || {}
        # trfc['transport_options_hash'] = new_resource.transport_options_hash || {}

        trfc['location'] = {}

        trfc['registry_options'] = {}
        trfc['registry_options']['machine_types'] = new_resource.machine_types
        trfc['registry_options']['ip_address']    = ip_address_given       if ip_address_given
        trfc['registry_options']['mac_address']   = mac_address_given      if mac_address_given
        trfc['registry_options']['subnet']        = new_resource.subnet    if new_resource.subnet
        trfc['registry_options']['netmask']       = new_resource.netmask   if new_resource.netmask
        trfc['registry_options']['domain']        = new_resource.domain    if new_resource.domain
        trfc['registry_options']['fqdn']          = new_resource.fqdn      if new_resource.fqdn
        trfc['registry_options']['memory']        = new_resource.memory    if new_resource.memory
        trfc['registry_options']['cpu_count']     = new_resource.cpu_count if new_resource.cpu_count
        trfc['registry_options']['cpu_type']      = new_resource.cpu_type  if new_resource.cpu_type
        trfc['registry_options']['arch']          = new_resource.arch      if new_resource.arch
        # trfc['registry_options'] = Chef::Mixin::DeepMerge.merge(new_resource.registry_options_hash,
        # trfc['registry_options'])

        trfc['machine_options']  = {}
        trfc['machine_options']['transport_options']  = {}
        trfc['machine_options']['transport_options']['ssh_options'] = {} unless new_resource.ssh_options
        trfc['machine_options']['transport_options']['host']                    = ip_address_given       if ip_address_given
        trfc['machine_options']['transport_options']['ip_address']              = ip_address_given       if ip_address_given
        trfc['machine_options']['transport_options']['username']                = new_resource.ssh_user if new_resource.ssh_user
        trfc['machine_options']['transport_options']['host_name']               = new_resource.hostname if new_resource.hostname
        trfc['machine_options']['transport_options']['ssh_options']             = new_resource.ssh_options if new_resource.ssh_options
        trfc['machine_options']['transport_options']['ssh_options']['user']     = new_resource.ssh_user if new_resource.ssh_user
        trfc['machine_options']['transport_options']['ssh_options']['password'] = new_resource.ssh_pass if new_resource.ssh_pass
        trfc['machine_options']['transport_options']['ssh_options']['keys']     = new_resource.ssh_keys if new_resource.ssh_keys
        # trfc['machine_options']['transport_options'] = Chef::Mixin::DeepMerge.merge(new_resource.transport_options_hash,
        # trfc['machine_options']['transport_options'])

        log_info("trfc = #{trfc}")
        trfc
      end

      ##
      #
      # Whether or Not to Reach out and Grab the Specs From a New Available Machine
      #
      def do_retrieve_specs?
        log_info("do_retrieve_spec value_for_file_name = #{value_for_file_name}")
        if @do_retrieve_spec
          return @do_retrieve_spec
        else
          @do_retrieve_spec ||= begin
            if valid_mac?(new_resource.name)
              false
            else
              new_resource.retrieve_specs
            end
          end
        end
      end

      def save_to_data_bag?
        if @save_to_data_bag
          return @save_to_data_bag
        else
          @save_to_data_bag ||= begin
            if ((new_resource.data_bag_only_if_encrypted && Chef::Config[:encrypted_data_bag_secret]) ||
                (new_resource.save_to_data_bag && !new_resource.data_bag_only_if_encrypted) ||
                !Chef::Config[:solo])
              true
            else
              false
            end
          end
        end
      end

      def save_to_file?
        new_resource.save_to_file
      end

      ##
      #
      # Path to the File Entry On Disk
      #
      def registry_machine_file_path
        if @registry_machine_file_path
          return @registry_machine_file_path
        else
          @registry_machine_file_path = ::File.join(registry_path, "#{value_for_file_name}.json")
          @registry_machine_file_path
        end
      end

      def registry_path
        if ENV['REGISTRY_APP_ROOT']
          ::File.join(ENV['REGISTRY_APP_ROOT'], ".chef/provisioning/registry")
        else
          new_resource.registry_path
        end
      end

      ##
      #
      # The Name Of The Entry File minus Extension.
      #
      # Can Be the node name when allocated or Dashed IP or Munged MAC when creating
      #    an available entry
      #
      def value_for_file_name
        @value_for_file_name ||= begin
          ip_addr = ip_address_given? ? ip_address_given.gsub('.','-') : ip_address_given
          mac_addr = mac_address_given
          mac_addr_to_mac = mac_addr ? mac_addr.to_mac : false
          ret_val = ( ip_addr || mac_addr_to_mac || new_resource.name)
          ret_val
        end
      end

      ##
      #
      # This Section Does IP Mapping, Matching, Validation Etc.
      #
      def name_and_ip_both_given_and_match?
        if new_resource.ip_address
          if (new_resource.name == new_resource.ip_address)
            return true
          else
            raise "new_resources name and ip_addr are both ip addrs but do not match"
          end
        else
          return true
        end
      end

      def ip_address_given?
        if new_resource.ip_address
          raise "new_resource.ip_address was given and is invalid" unless valid_ip?(new_resource.ip_address)
        end
        if valid_ip?(new_resource.name)
          return "name" if name_and_ip_both_given_and_match?
        elsif new_resource.ip_address
          return "ip_addr"
        else
          return false
        end
      end

      def ip_address_given
        if @given_ip_addr
          return @given_ip_addr
        else
          @given_ip_addr = value_or_false(ip_address_given_value)
          @given_ip_addr
        end
      end

      def ip_address_given_value
        return @given_ip_addr_value if @given_ip_addr_value
        case ip_address_given?
        when "name"
          @given_ip_addr_value = new_resource.name
        when "ip_addr"
          @given_ip_addr_value = new_resource.ip_address
        else
          @given_ip_addr_value = "false"
        end
        @given_ip_addr_value
      end


      ##
      #
      # This Section Does MAC Address Mapping, Matching, Validation Etc.
      #
      def mac_address_given?
        if new_resource.mac_address
          raise "new_resource.mac_address was given and is invalid" unless valid_mac?(new_resource.mac_address)
        end
        if valid_mac?(new_resource.name)
          return "name" if name_and_mac_both_given_and_match?
        elsif new_resource.mac_address
          return "mac_addr"
        else
          return false
        end
      end

      def mac_address_given
        return @given_mac_addr if @given_mac_addr
        @given_mac_addr = value_or_false(mac_address_given_value)
        @given_mac_addr
      end

      def mac_address_given_value
        case mac_address_given?
        when "name"
          ret_val = new_resource.name
        when "mac_addr"
          ret_val = new_resource.mac_address
        else
          ret_val = false
        end
        ret_val
      end

      def name_and_mac_both_given_and_match?
        if new_resource.mac_address
          if (new_resource.name.to_mac == new_resource.mac_address.to_mac)
            return true
          else
            raise "new_resources name and mac_address are both mac addrs but do not match"
          end
        else
          return true
        end
      end

      def valid_mac?(val)
        if val.valid_mac?(strict: true)
          return true
        else
          return false
        end
      end

      ##
      # Helper
      # TODO move to common module
      def value_or_false(value)
        if value
          if value == "false"
            return false
          else
            return value.to_s
          end
        else
          return false
        end
      end

      def ensure_directories
        use_registry_path = registry_path
        Cheffish.inline_resource(self, :create) do
          directory use_registry_path do
            recursive true
          end
        end
      end

    end
  end
end
