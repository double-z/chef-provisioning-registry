# Chef::Provisioning::Registry

This is a registry for  chef provisioning. It can be be used with any drivers, and defaults to the ssh_driver when a registry match is found.

There are two ways to add an entry to the registry:

1. A `registry_machine` resource that can be used in recipes

2. An Api that uses scripts to register via a curl post

The scripts and API will also create a `provisioning` user and keys for that user and add them to the api.

basically, the scripts tell the API this is what i am - CPU Count, Memory, Etc. - and this is how you get to me. Much more can potentially be added or removed going forwared.

This is is very early development, but fully functional. 

A demo is included in `docs/examples`, usage of demo is explained below.

The main thrust of usage is a new machine resource called `machine_registry` that searches the registry if told to and defaults to whatever driver is given - vagrant in the demo example - if no match is found. 

It looks like this:

		machine_registry "one" do
		  action [:ready, :setup, :converge]
		  converge true
		  use_registry true
		  registry_options 'machine_type' => 'rails_server', 'memory' => ['235', '256']
		end

note memory match is done via an array that will match a range like above, cause memory registers are not exact.

the scripts used can be seen here:

http://bit.ly/notify_chef_provisioning_registry_api

and here:

http://bit.ly//metal_spec_sh_latest

api output json can be seen here:

https://gist.github.com/double-z/abd332ff61875e1cbeff

and the data bag created for a match can be seen here:

https://gist.github.com/double-z/26f5e73c88c052c11a34


more coming...

Requirements
------------

The Demo was tested on Ubuntu 12.04. should work wherever with minimal to no mods.

For the demo, chefdk is necessary.

Gems are in `docs/examples/gems` for now.

Demo Usage
-----

To test it out, clone the repo:

`git clone https://github.com/double-z/chef-provisioning-registry.git`

cd chef-provisioning-registry/docs/examples

There is a Vagrantfile with two machines, one for registering with the `registry_machine` resource, the othere for api.

run `vagrant up`
the ssh to the api register machine `vagrant ssh register-via-api`
then `sudo -s`
setup the vm by running `/vagrant/setup_vagrant_vm.sh`

after that you need to set up the hosts file. the API will listen 0.0.0.0 on your local machine, so add the following line to the vagrant box hosts file

`$LOCAL_IP registry-api`

where LOCAL_IP is an ip that vagrant can talk to on your local machine.

the scripts will log to /tmp

after that logout of the vagrant box and run `setup.sh` which will install the required gems using ChefDK

then open another tab, and from the docs/examples directory run `start_api.sh` which will start the api in the foreground. When the machine registers you will see the json entry it will create outputted there.

once the api is started reload the vagrant box and it will register with API on boot.

`vagrant reload register-with-api`

once you see the entry hit  the api

run `run_chef.sh` and three nodes will be converged, one using the vagrant_driver and two using the registry. the other registry entry is created via the `registry_machine` resource in the examples recipe.

License and Authors
-------------------
Authors: Zack Zondlo
