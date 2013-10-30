# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcloud/version'

Gem::Specification.new do |s|
  s.name        = 'vcloud-tools'
  s.version     = VCloud::VERSION
  s.authors     = ['Nick Osborn']
  s.summary     = %q{Tools for VMware vCloud}
  s.homepage    = 'https://github.com/alphagov/vcloud-tools'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) {|f| File.basename(f)}
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split($/)
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'bundler'
  s.add_runtime_dependency 'thor', '~> 0.18.1'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.14.1'
  s.add_development_dependency 'rspec-mocks', '~> 2.14.4'
end
