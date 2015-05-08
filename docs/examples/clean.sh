#!/bin/bash
VAGRANT_DIR="/home/vagrant/"
if [ -d $VAGRANT_DIR ]
then
  echo "NOT VAGRANT"
else
  echo "VAGRANT"
#  vagrant destroy
fi
rm nodes/* clients/* .chef/provisioning/ssh/* .chef/provisioning/registry/* data_bags/registry/*
