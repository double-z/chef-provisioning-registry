#!/bin/bash
REGISTRY_APP_ROOT=`pwd` chef exec chef-client -z -o vagrant::test_consul
#REGISTRY_APP_ROOT=`pwd` chef exec chef-client -z -o vagrant::test_demo
#REGISTRY_APP_ROOT=`pwd` chef exec chef-client -z -o vagrant::test_one_vagrant_and_two_registry
