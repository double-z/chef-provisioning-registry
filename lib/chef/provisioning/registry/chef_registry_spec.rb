require 'net/http'
require 'chef_metal'
require 'cheffish'
require 'chef/provisioning/registry/helpers'
require 'chef/provisioning/registry/registry_spec'

#
# Specification for a registry. Sufficient information to find and contact it
# after it has been set up.
#

class Chef
  module Provisioning
    module Registry
      class ChefRegistrySpec < RegistrySpec
        include Chef::Provisioning::Registry::Helpers

        def initialize(node, chef_server = false)
          super(node)
          @chef_server = chef_server
        end

        def self.get_or_empty(new_resource, chef_server = Cheffish.default_chef_server)
          val = (self.get(new_resource.name, chef_server) || self.empty(new_resource.name, chef_server))
          val
        end

        #
        # Get a RegistrySpec from the chef server.  If the node does not exist on the
        # server, it returns nil.
        #
        def self.get(name, chef_server = Cheffish.default_chef_server)
          chef_api = Cheffish.chef_server_api(chef_server)
          begin
            data = chef_api.get("/data/registry/#{name}")
            data['machine_options'] = strings_to_symbols(data['machine_options'])
            data['machine_options'].delete(:convergence_options) if data['machine_options'][:convergence_options]
            get = ChefRegistrySpec.new(data, chef_server)
          rescue Net::HTTPServerException => e
            if e.response.code == '404'
              return nil
            else
              raise
            end
          end
        end

        def get
          begin
            if self.registry_data
              self.registry_data
            end
          rescue
          end
        end

        def get_status
          begin
            if self.registry_data
              self.delete_convergence_options
              _self_registry_data = self.registry_data
              return _self_registry_data['status']
            end
          rescue
          end
        end

        def driver_url
          begin
            if self.registry_data
              self.delete_convergence_options
              _self_registry_data = self.registry_data
              return _self_registry_data['location']['driver_url'] rescue false
            end
          rescue
          end
        end

        # Creates a new empty RegistrySpec with the given name.
        def self.empty(name, chef_server = Cheffish.default_chef_server)
          ChefRegistrySpec.new({'id' => name}, chef_server)
        end


        #
        # Globally unique identifier for this registry. Does not depend on the registry's
        # location or existence.
        #
        def id
          ChefRegistrySpec.id_from(chef_server, name)
        end

        def self.id_from(chef_server, name)
          "#{chef_server[:chef_server_url]}/data/registry/#{name}"
        end

        def save_spec(action_handler)
          self.delete_convergence_options
          _self = self
          ChefMetal.inline_resource(action_handler) do
            registry_machine _self.name do
              action :update_existing
              spec_self _self
            end
          end
        end

        def save_data_bag(action_handler, dont_check = false)
          # # Save the entry to registry_path file.
          self.delete_convergence_options if dont_check
          _self = self
          _self_registry_data = stringify_keys(_self.registry_data)
          _chef_server = _self.chef_server
          existing_entry = dont_check ? false : ChefRegistrySpec.get(_self.name, _chef_server)
          existing_entry_data = stringify_keys(existing_entry.registry_data) if existing_entry
          strip_hash_nil(existing_entry_data) if existing_entry
          strip_hash_nil(_self_registry_data)
          values_same = existing_entry ? existing_entry_data.eql?(_self_registry_data) : false
          unless values_same
            ChefMetal.inline_resource(action_handler) do
              chef_data_bag_item _self.name do
                action :create
                data_bag 'registry'
                chef_server _chef_server
                raw_data _self.registry_data
              end
            end
          else
            true
          end
        end

        def save_file(action_handler, dont_check = false)
          # Save the entry to registry_path file.
          self.delete_convergence_options if dont_check

          _self = self
          _self_registry_data = stringify_keys(_self.registry_data)
          _chef_server = _self.chef_server
          registry_data_json = JSON.parse(_self_registry_data.to_json)
          # puts "_self_registry_data['location'] #{_self.registry_data}"
          file_name = _self_registry_data['location']['registry_machine_path']
          existing_entry = dont_check ? false : false # ChefRegistrySpec.get(_self.name, _chef_server)
          existing_entry_data = stringify_keys(existing_entry.registry_data) if existing_entry
          strip_hash_nil(existing_entry_data) if existing_entry
          strip_hash_nil(_self_registry_data)
          values_same = existing_entry ? existing_entry_data.eql?(_self_registry_data) : false      # existing_entry = dont_check ? false : ChefRegistrySpec.get(_self.name, _chef_server)
          unless values_same
            ChefMetal.inline_resource(action_handler) do
              file file_name do
                content JSON.pretty_generate(registry_data_json)
                action :create
              end
            end
          else
            true
          end
        end

        def save_consul(data)
          log_ts "DATA: #{data}"
          log_ts "DATAID: #{data['id']}"

          # v = "http://localhost:8500/v1/kv/#{entry_name}?raw"
          # uri = URI.parse(v)
          # response = Net::HTTP.get_response(uri)

          # urlb = "localhost:8500"
          urlb = "http://localhost:8500"
          urin = "/v1/kv/provisioning-registry/allocated/#{data['id']}"
          # urin = "/v1/kv/provisioning-registry/allocated/#{data['id']}"

          jsonbody = data.to_json
          uri = URI.parse("#{urlb}#{urin}")
          http = Net::HTTP.new(uri.host, uri.port)

          responsen = http.request_put(uri.request_uri, jsonbody)
          log_ts "SAVE responsen #{responsen.inspect}"
          if data['location'] &&
              data['location']['matched_registry_file']
            log_ts "MRF SAVE #{data['location']['matched_registry_file']}"


            urld = "/v1/kv/provisioning-registry/available/#{data['location']['matched_registry_file_id']}"
            urid = URI.parse("#{urlb}#{urld}")
            httpd = Net::HTTP.new(urid.host, urid.port)
            responsed = httpd.delete(urid.request_uri)
          end

          # def put(path, headers = {}, body = "")
          #   uri = URI.parse("#{@base_url}#{path}")
          #   http = Net::HTTP.new(uri.host, uri.port)
          #   request = Net::HTTP::Put.new(uri.request_uri)
          #   request.basic_auth @username, @password unless @username.nil?
          #   headers.keys.each do |key|
          #     request[key] = headers[key]
          #   end
          #   request.body = body
          #   http.request(request)
          # end

          # def delete(path)
          #   uri = URI.parse("#{@base_url}#{path}")
          #   http = Net::HTTP.new(uri.host, uri.port)
          #   request = Net::HTTP::Delete.new(uri.request_uri)
          #   request.basic_auth @username, @password unless @username.nil?
          #   http.request(request)
          # end
        end

        #
        # Save this node to the server.  If you have significant information that
        # could be lost, you should do this as quickly as possible.  Data will be
        # saved automatically for you after allocate_registry and ready_registry.
        #
        def save(action_handler)
          # # Save the node to the server.
          self.delete_convergence_options
          _self = self
          _self_registry_data = stringify_keys(_self.registry_data)
          _chef_server = _self.chef_server
          existing_entry = ChefRegistrySpec.get(_self.name, _chef_server)
          existing_entry_data = stringify_keys(existing_entry.registry_data) if existing_entry
          strip_hash_nil(existing_entry_data) if existing_entry
          strip_hash_nil(_self_registry_data)
          values_same = existing_entry ? existing_entry_data.eql?(_self_registry_data) : false
          if _self_registry_data['location'] &&
              _self_registry_data['location']['matched_registry_file'] &&
              ::File.exists?(_self_registry_data['location']['matched_registry_file'])
            mark_matched_registry_file_taken(_self_registry_data['location']['matched_registry_file'])
          end
          unless values_same
            #save_consul(_self_registry_data)
            save_data_bag(action_handler, true)
            save_file(action_handler, true)
          else
            true
          end
        end

        def mark_matched_registry_file_taken(matched_registry_file)
          content = JSON.parse(File.read(matched_registry_file))
          content.merge!({ "status" => "allocated"})
          ::File.open(matched_registry_file,"w") do |new_json|
            new_json.puts ::JSON.pretty_generate(JSON.parse(content.to_json))
          end
        end

        def strip_hash_nil(val)
          vvv = case val
          when Hash
            cleaned_val = val.delete_if { |kk,vv| vv.nil? || (vv && vv.is_a?(String) && vv.empty?) }
            cleaned_val.each do |k,v|
              case v
              when Hash
                strip_hash_nil(v)
              when Array
                v.flatten!
                v.uniq!
              end
            end
          end
          vvv
        end

        def delete_file_entry(action_handler)
          # Delete the file.
          registry_entry_file_path = ::File.join(registry_path, "#{_self.name.to_s}.json")
          _self = self
          _chef_server = _self.chef_server
          ChefMetal.inline_resource(action_handler) do
            file registry_entry_file_path do
              action :delete
            end
          end
        end

        def delete_data_bag_item_entry(action_handler)
          # Save the data bag item
          _self = self
          _chef_server = _self.chef_server
          ChefMetal.inline_resource(action_handler) do
            chef_data_bag_item _self.name do
              data_bag 'registry'
              chef_server _chef_server
              action :delete
            end
          end
        end

        def delete(action_handler)
          # Delete the Registry Entry.
          delete_data_bag_item_entry(action_handler)
          # delete_file_entry(action_handler)
        end

        protected

        attr_reader :chef_server

        #
        # Chef API object for the given Chef server
        #
        def chef_api
          Cheffish.server_api_for(chef_server)
        end

        def self.strings_to_symbols(data)
          if data.is_a?(Hash)
            result = {}
            data.each_pair do |key, value|
              result[key.to_sym] = strings_to_symbols(value)
            end
            result
          else
            data
          end
        end

        def self.stringify_keys(hash)
          hash.inject({}){|result, (key, value)|
            new_key   = case key
            when Symbol
              key.to_s
            else
              key
            end

            new_value = case value
            when Hash
              stringify_keys(value)
            when String
              value
            else
              value
            end

            result[new_key] = new_value
            result
          }
        end

        def stringify_keys(hash)
          hash.inject({}){|result, (key, value)|
            new_key   = case key
            when Symbol
              key.to_s
            else
              key
            end

            new_value = case value
            when Hash
              stringify_keys(value)
            when String
              value
            else
              value
            end

            result[new_key] = new_value
            result
          }
        end

      end
    end
  end
end
