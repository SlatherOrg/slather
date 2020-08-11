# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slather/version'

Gem::Specification.new do |spec|
  spec.name          = 'slather'
  spec.version       = Slather::VERSION
  spec.authors       = ['Mark Larsen']
  spec.email         = ['mark@venmo.com']
  spec.summary       = %q{Test coverage reports for Xcode projects}
  spec.homepage      = 'https://github.com/SlatherOrg/slather'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'cocoapods', '~> 1.10.beta.1'
  spec.add_development_dependency 'json_spec', '~> 1.1'
  spec.add_development_dependency 'equivalent-xml', '~> 0.6'

  spec.add_dependency 'clamp', '~> 1.3'
  spec.add_dependency 'xcodeproj', '~> 1.7'
  spec.add_dependency 'nokogiri', '~> 1.8'
  spec.add_dependency 'CFPropertyList', '>= 2.2', '< 4'

  spec.add_runtime_dependency 'activesupport'
end
