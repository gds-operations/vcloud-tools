require 'gem_publisher'

task :publish_gem do |t|
  gem = GemPublisher.publish_if_updated("vcloud-tools.gemspec", :rubygems)
  puts "Published #{gem}" if gem
end
