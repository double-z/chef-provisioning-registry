require 'chef/provisioning/ssh_driver'
require 'chef/provisioning/registry'

registry_machine "192.168.33.72" do
  action :new_available
  machine_types ['app_server']
  retrieve_specs true
  ssh_user "vagrant"
  ssh_pass "vagrant"
end

machine_registry "one" do
  action [:ready, :setup, :converge]
  use_registry true
  registry_options 'machine_type' => 'rails_server', 'memory' => ['235', '256']
end

machine_registry "two" do
  action [:ready, :setup, :converge]
  use_registry true
  registry_options 'machine_type' => 'rails_server', 'memory' => ['235', '256']
end

ruby_block 'reload client config' do
  block do
    Dir.foreach('/etc/opscode') do |file_name|
      next if item == '.' or item == '..'
      scp_file File.absolute_path(file_name) do
        destination node['chef_server_tiered']['frontend_ip']
        source file_name
        hostname node['chef_server_tiered']['frontend_ip']
        username 'root'
        password 'abc123'
        action :upload
      end
    end
  end
end
