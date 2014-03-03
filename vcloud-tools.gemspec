# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcloud/version'

Gem::Specification.new do |s|
  s.name        = 'vcloud-tools'
  s.version     = Vcloud::VERSION
  s.authors     = ['Government Digital Service']
  s.summary     = %q{Tools for VMware vCloud}
  s.homepage    = 'https://github.com/alphagov/vcloud-tools'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) {|f| File.basename(f)}
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'bundler'
  s.add_runtime_dependency 'methadone'
  s.add_runtime_dependency 'vcloud-core', '>= 0.0.7'
  s.add_runtime_dependency 'hashdiff'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'rspec-mocks', '~> 2.14.4'
  s.add_development_dependency 'simplecov', '~> 0.8.2'
  s.add_development_dependency 'aruba', '~> 0.5.3'
  s.add_development_dependency 'cucumber', '~> 1.3.10'
  s.add_development_dependency 'jeweler', '~> 1.8.8'
end
