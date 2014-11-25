#!/bin/bash
vagrant destroy
rm nodes/* clients/* .chef/provisioning/ssh/* .chef/provisioning/registry/* data_bags/registry/*
