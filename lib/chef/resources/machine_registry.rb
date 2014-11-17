require 'chef/resource/lwrp_base'
require 'cheffish'
require 'chef/provisioning'
require 'cheffish/merged_config'

class Chef
class Resource
class MachineRegistry < Chef::Resource::Machine
  def initialize(*args)
    super
  end

  self.resource_name = "machine_registry"

  # Registry Options
  attribute :registry_options, :kind_of => Hash

  # Registry Driver
  attribute :use_registry

  # Registry Driver
  attribute :registry_driver,  :kind_of => String, :default => 'ssh'

  # Registry Options
  attribute :transport_options, :kind_of => Hash

  # Registry Path
  attribute :registry_path
  
  def load_prior_resource
    Chef::Log.debug "Overloading #{self.resource_name} load_prior_resource with NOOP"
  end
end
end
end
