# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slather/version'

Gem::Specification.new do |spec|
  spec.name          = "slather"
  spec.version       = Slather::VERSION
  spec.authors       = ["Mark Larsen"]
  spec.email         = ["mark@venmo.com"]
  spec.summary       = %q{Test coverage reports for Xcode projects}
  spec.homepage      = "https://github.com/SlatherOrg/slather"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "cocoapods", "~> 1.0"
  spec.add_development_dependency "json_spec", "~> 1.1.4"
  spec.add_development_dependency "equivalent-xml", "~> 0.5.1"

  spec.add_dependency "clamp", "~> 0.6"
  spec.add_dependency "xcodeproj", "~> 1.1"
  spec.add_dependency "nokogiri", "~> 1.6.3"
end
