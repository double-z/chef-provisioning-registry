#!/bin/bash

#USE_SHELL=`env | grep ^SHELL | sed "s/SHELL=\/bin\///g"`
#eval "$(chef shell-init $USE_SHELL)"
chef gem install chef-provisioning-vagrant --no-ri --no-rdoc
chef gem install ./gems/chef-provisioning-registry-0.0.2.gem --no-ri --no-rdoc 
chef gem install ./gems/chef-provisioning-ssh-0.0.2.gem  --no-ri --no-rdoc
