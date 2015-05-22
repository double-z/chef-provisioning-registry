require 'sinatra'

configure do
  set :bind, '0.0.0.0'
end

get "/v1/register/consul/:name" do
  ip = params[:name].gsub('-', '.')
  `consul join #{ip}`
end

# curl -X PUT http://localhost:8500/v1/kv/provisioning-registry/available/test -d "{\"id\": \"$NAME\", \"registry_options\": {\"ssh_user\": \"$USER_NAME\", \"machine_types\": [\"$MACHINE_TYPE\"], \"password\": \"$PASSWORD\", \"memory\": \"$TOTAL_MEM\", \"swap\": \"$TOTAL_SWAP\", \"cpu_count\": \"$TOTAL_CPU\", \"ip_address\": \"$DEFAULT_IFACE_IP\", \"subnet\": \"$DEFAULT_IFACE_SUBNET\", \"broadcast\": \"$DEFAULT_IFACE_BROADCAST\", \"mac_address\": \"$DEFAULT_IFACE_MAC\", \"root_disk_space\": \"$ROOT_DISK_SPACE\"}}"

# echo;echo;echo "{\"id\": \"$NAME\", \"registry_options\": {\"ssh_user\": \"$USER_NAME\", \"machine_types\": [\"$MACHINE_TYPE\"], \"password\": \"$PASSWORD\", \"memory\": \"$TOTAL_MEM\", \"swap\": \"$TOTAL_SWAP\", \"cpu_count\": \"$TOTAL_CPU\", \"ip_address\": \"$DEFAULT_IFACE_IP\", \"subnet\": \"$DEFAULT_IFACE_SUBNET\", \"broadcast\": \"$DEFAULT_IFACE_BROADCAST\", \"mac_address\": \"$DEFAULT_IFACE_MAC\", \"root_disk_space\": \"$ROOT_DISK_SPACE\"}, \"machine_options\": { \"transport_options\": { \"ssh_options\": { \"user\": \"$USER_NAME\", \"password\": \"$PASSWORD\"}}}}";echo;echo

# curl -X PUT http://localhost:8500/v1/kv/provisioning-registry/available/consul -d "{\"id\": \"$NAME\", \"registry_options\": {\"ssh_user\": \"$USER_NAME\", \"machine_types\": [\"$MACHINE_TYPE\"], \"password\": \"$PASSWORD\", \"memory\": \"$TOTAL_MEM\", \"swap\": \"$TOTAL_SWAP\", \"cpu_count\": \"$TOTAL_CPU\", \"ip_address\": \"$DEFAULT_IFACE_IP\", \"subnet\": \"$DEFAULT_IFACE_SUBNET\", \"broadcast\": \"$DEFAULT_IFACE_BROADCAST\", \"mac_address\": \"$DEFAULT_IFACE_MAC\", \"root_disk_space\": \"$ROOT_DISK_SPACE\"}, \"machine_options\": { \"transport_options\": { \"ssh_options\": { \"user\": \"$USER_NAME\", \"password\": \"$PASSWORD\"}}}}"