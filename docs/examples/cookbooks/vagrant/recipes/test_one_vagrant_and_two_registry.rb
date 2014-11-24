require 'chef/provisioning/ssh_driver'
require 'chef/provisioning/registry'

registry_machine "192.168.33.22" do
  action :new_available
  #action :nothing
  machine_types ['rails_server']
  retrieve_specs true
  ssh_user "vagrant"
  ssh_pass "vagrant"
  ssh_keys [::File.join(ENV['HOME'], ".vagrant/insecure_private_key")]
end


machine_registry 'web' do
  action [:ready, :setup, :converge]
  #action :destroy
  driver 'vagrant'
  machine_options :vagrant_options => {
    'vm.box' => 'opscode-ubuntu-12.04'
  }
  use_registry true
  converge true
  registry_options  ({
	 'machine_types' => 'some_server'
	})
end

machine_registry "one" do
  action [:ready, :setup, :converge]
  #action :destroy
  converge true
  use_registry true
  registry_options 'machine_type' => 'rails_server', 'memory' => ['235', '256']
end


machine_registry "two" do
  action [:ready, :setup, :converge]
  #action :destroy
  converge true
  use_registry true
  registry_options 'machine_type' => 'rails_server', 'memory' => ['235', '256']
end
