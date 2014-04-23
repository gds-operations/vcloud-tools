# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vcloud/tools/version'

Gem::Specification.new do |s|
  s.name        = 'vcloud-tools'
  s.version     = Vcloud::Tools::VERSION
  s.authors     = ['Government Digital Service']
  s.summary     = %q{Tools for VMware vCloud}
  s.homepage    = 'https://github.com/alphagov/vcloud-tools'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) {|f| File.basename(f)}
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'vcloud-core', '>= 0.0.12'
  s.add_runtime_dependency 'vcloud-edge_gateway', '>= 0.2.3'
  s.add_runtime_dependency 'vcloud-launcher', '>= 0.0.3'
  s.add_runtime_dependency 'vcloud-net_launcher', '>=0.0.2'
  s.add_runtime_dependency 'vcloud-walker', '>= 3.2.1'
  s.add_development_dependency 'gem_publisher', '1.2.0'
  s.add_development_dependency 'rake'
end
