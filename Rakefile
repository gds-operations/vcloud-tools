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
  # Set a bogus Fog credential, otherwise it's possible for the unit
  # tests to accidentially run (and succeed against!) an actual 
  # environment, if Fog connection is not stubbed correctly.
  ENV['FOG_CREDENTIAL'] = 'random_nonsense_owiejfoweijf'
  task.pattern = FileList['spec/vcloud/**/*_spec.rb']
end

RSpec::Core::RakeTask.new('integration:quick') do |t|
  t.rspec_opts = %w(--tag ~take_too_long)
  t.pattern = FileList['spec/integration/**/*_spec.rb']
end

RSpec::Core::RakeTask.new('integration:all') do |t|
  t.pattern = FileList['spec/integration/**/*_spec.rb']
end

task :default => [:spec,:features]

Jeweler::Tasks.new do |gem|
  gem.name = 'vcloud-tools'
  gem.version = Vcloud::VERSION
end
Jeweler::RubygemsDotOrgTasks.new
