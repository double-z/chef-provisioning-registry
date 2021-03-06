require 'chef/provisioning/ssh_driver'
require 'chef/provisioning/registry'

registry_machine "192.168.33.72" do
  action :new_available
  machine_types ['app_server']
  retrieve_specs true
  ssh_user "vagrant"
  ssh_pass "vagrant"
  ssh_keys [::File.join(ENV['HOME'], ".vagrant/insecure_private_key")]
end

machine_registry "lb" do
  use_registry true
  registry_options 'machine_type' => 'lb_server', 'memory' => ['235', '256']
end

machine_registry "app01" do
  use_registry true
  registry_options 'machine_type' => 'app_server', 'memory' => ['235', '256']
end

machine_registry "app02" do
  use_registry true
  registry_options 'machine_type' => 'app_server', 'memory' => ['235', '256']
end

machine_registry "db" do
  use_registry true
  registry_options 'machine_type' => 'db_server', 'memory' => ['990', '1024']
end

machine_registry "cache" do
  use_registry true
  registry_options 'machine_type' => 'cache_server', 'memory' => ['490', '512']
end
