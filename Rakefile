require 'bundler'
require "bundler/gem_tasks"
require 'rake/clean'
require 'rake/testtask'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'jeweler'
require 'vcloud/version'

include Rake::DSL

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.pattern = 'test/tc_*.rb'
end

CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty --no-source -x"
  t.fork = false
end

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = FileList['spec/vcloud/*_spec.rb']
end

RSpec::Core::RakeTask.new(:integration_test) do |task|
  task.pattern = FileList['spec/integration/*_spec.rb']
end

task :default => [:spec,:features]

Jeweler::Tasks.new do |gem|
  gem.name = 'vcloud-tools'
  gem.version = Vcloud::VERSION
end
Jeweler::RubygemsDotOrgTasks.new
