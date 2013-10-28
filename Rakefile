require "bundler/gem_tasks"
require 'rake/testtask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
task.pattern = FileList['spec/**/*_spec.rb']
end
