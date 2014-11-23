require 'rubygems'
require 'fileutils'
require 'sinatra'
require 'mixlib/shellout'
require 'chef'
require 'chef/provisioning'
require 'cheffish'
require 'chef/config'
require 'chef/knife'
require 'chef/run_list/run_list_item'
require 'cheffish/basic_chef_client'
require 'cheffish/server_api'
require 'chef/knife'
require 'chef/config_fetcher'
require 'chef/log'
require 'chef/application'
require 'chef/provisioning/registry/data_handler/for_api'
require 'chef/provisioning/registry/chef_registry_spec'

# APP_ROOT = File.expand_path('..', File.dirname(__FILE__)) unless defined? APP_ROOT
APP_ROOT = ENV['REGISTRY_APP_ROOT']
configure do
  set :bind, '0.0.0.0'
end

post '/v1/registry' do

  registry_path = ::File.expand_path("#{APP_ROOT}/.chef/provisioning/registry")
  FileUtils.mkdir_p(registry_path)

  datafile = params[:data]
  payload = datafile[:tempfile].read

  data_handler = Chef::Provisioning::Registry::DataHandler::ForApi.new(payload, registry_path)

  if data_handler.keyname && !::File.exists?(data_handler.keyname)
    if data_handler.ssh_key_value
      ::File.open(data_handler.keyname, 'wb') do |file|
        file.write(data_handler.ssh_key_value)
      end
      ::File.chmod(00600, data_handler.keyname)
    end
  end

  ##
  # Setup Config
  config_file_path = ::File.expand_path("#{APP_ROOT}/.chef/knife.rb")
  chef_config = Chef::Config
  config_fetcher = Chef::ConfigFetcher.new(config_file_path)
  config_content = config_fetcher.read_config
  chef_config.from_string(config_content, config_file_path)
  config = Cheffish.profiled_config(chef_config)
  config[:local_mode] = true
  chef_server = Cheffish.default_chef_server(config)

  ##
  # Action Handler
  # TODO make right
  action_handler = Chef::Provisioning::ActionHandler.new

  ##
  # Chef Registry Spec
  registry_spec = Chef::Provisioning::Registry::ChefRegistrySpec.new(data_handler.api_hash, chef_server)

  ##
  # Save
  # TODO get respect_inline working. to file only for now
  #
  # registry_spec.save_data_bag(action_handler)
  registry_spec.save_file(action_handler)
  # registry_spec.save(action_handler) # This Saves to Both
  
  "\n OUT \n Payload Recieved is: \n\n#{payload}\n ChefRegistrySpec inspect is: \n\n#{registry_spec.inspect} \n DataHandler is \n\n#{data_handler.inspect}\n"
end

