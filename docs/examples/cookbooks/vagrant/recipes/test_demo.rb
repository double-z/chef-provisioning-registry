require 'chef/provisioning/ssh_driver'
require 'chef/provisioning/registry'

registry_machine "172.20.20.72" do
  action :new_available
  machine_types ['app_server']
  retrieve_specs true
  ssh_user "vagrant"
  ssh_pass "vagrant"
end

machine_registry "lb" do
  use_registry true
  registry_options 'machine_types' => 'lb_server', 'memory' => ['235', '256']
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
  registry_options 'machine_type' => 'cache_server', 'memory' => ['480', '512']
end
