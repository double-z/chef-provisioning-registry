# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef/provisioning/registry/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-provisioning-registry"
  spec.version       = Chef::Provisioning::Registry::VERSION
  spec.authors       = ["double-z"]
  spec.email         = ["zackzondlo@gmail.com"]
  spec.summary       = %q{Chef Provisioning Registry}
  spec.description   = spec.summary
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'mac_address'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'chef-provisioning'
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
