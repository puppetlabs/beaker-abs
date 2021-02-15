# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'beaker-abs'

Gem::Specification.new do |spec|
  spec.name          = "beaker-abs"
  spec.version       = BeakerAbs::Version::STRING
  spec.authors       = ["Josh Cooper", "Rick Bradley"]
  spec.email         = ["josh@puppet.com", "rick@puppet.com"]

  spec.summary       = %q{Let's test Puppet, using hosts provisioned by Always Be Scheduling service.}
  spec.description   = %q{Adds a custom hypervisor that uses hosts provisioned by the Always Be Scheduling service.}
  spec.homepage      = "https://github.com/puppetlabs/beaker-abs"
  spec.license       = "Apache-2.0"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "beaker", "~> 4.0"
  spec.add_dependency "vmfloaty", ">= 1.0", "< 1.3"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"

end
