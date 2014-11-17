require 'chef/resource/lwrp_base'
require 'chef/resource/machine'
require 'cheffish'
require 'chef/provisioning'
require 'cheffish/merged_config'

class Chef
  class Resource
    class RegistryMachine < Chef::Resource::LWRPBase

  # def initialize(*args)
  #   super
  #   @machines = []
  #   @driver = run_context.chef_metal.current_driver
  #   @chef_server = run_context.cheffish.current_chef_server
  #   @machine_options = run_context.chef_metal.current_machine_options
  # end
  self.resource_name = 'registry_machine'
  
  actions :new_available, :nothing

  default_action :nothing
#=========
  attribute :machines, :kind_of => [ Array ]
  attribute :driver
  attribute :node_data
  attribute :machine_options
  attribute :from_recipe
  #=========
  attribute :name,
    :kind_of => [String]

  attribute :registry_path,
    :kind_of => [String]

  attribute :ip_address,
  	:kind_of => [String,FalseClass],
    :default => false

  attribute :mac_address,
  	:kind_of => [String,FalseClass],
    :default => false

  attribute :hostname,
  	:kind_of => [String]

  attribute :ssh_user,
    :kind_of => [String]

  attribute :password,
    :kind_of => [String]

  attribute :ssh_pass,
    :kind_of => [String]    
 
  attribute :ssh_keys,
    :kind_of => [String,Array]
    # # :default => []
    #  :kind_of => [String,Array,FalseClass],
    # :default => false

  attribute :subnet,
  	:kind_of => [String]

  attribute :domain,
  	:kind_of => [String]

  attribute :fqdn,
  	:kind_of => [String]

  attribute :metal_spec_script,
    :kind_of => [String],
    :default => "http://bit.ly/metal_spec_sh_latest"

  attribute :retrieve_specs, 
    :kind_of => [TrueClass,FalseClass],
    :default => false

  attribute :data_bag_only_if_encrypted,
    :kind_of => [TrueClass,FalseClass],
    :default => false

  attribute :save_to_data_bag,
    :kind_of => [TrueClass,FalseClass],
    :default => false

  attribute :save_to_file,
    :kind_of => [TrueClass,FalseClass],
    :default => true

  attribute :ignore_retrieve_failures,
    :kind_of => [TrueClass,FalseClass],
    :default => false

  attribute :machine_types, 
  	:kind_of => [Array],
  	:default => Array.new

  attribute :memory, 
  	:kind_of => [String]

  attribute :cpu_count, 
  	:kind_of => [String]

  attribute :cpu_type, 
  	:kind_of => [String]

  attribute :arch, 
  	:kind_of => [String]

  attribute :netmask,
    :kind_of => [String]

  attribute :ssh_options,
    :kind_of => [Hash]

end
end
end