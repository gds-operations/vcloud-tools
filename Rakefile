require "bundler/gem_tasks"
require 'rake/testtask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = FileList['spec/vcloud/*_spec.rb']
end

RSpec::Core::RakeTask.new(:integration_test) do |task|
  if ENV['VCLOUD_TEST_VDC'].nil?
    puts 'You must set VCLOUD_TEST_VDC to the name of your vDC'
    exit
  end
  if ENV['VCLOUD_TEST_CATALOG'].nil?
    puts 'You must set VCLOUD_TEST_CATALOG to the name of your org catalog'
    exit
  end
  if ENV['VCLOUD_TEST_TEMPLATE'].nil?
    puts 'You must set VCLOUD_TEST_TEMPLATE to the name of your vapp template'
    exit
  end
  task.pattern = FileList['spec/integration/*_spec.rb']
end
