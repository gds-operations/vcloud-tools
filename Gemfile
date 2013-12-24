source 'http://rubygems.org'

gemspec

if ENV['VCLOUD_TOOLS_DEV_FOG_MASTER']
  gem 'fog', :git => 'git@github.com:fog/fog.git', :branch => 'master'
elsif ENV['VCLOUD_TOOLS_DEV_FOG_LOCAL']
  gem 'fog', :path => '../fog'
else
  # Fog 1.19.0 RubyGem is ok for now
  #gem 'fog', :git => 'git@github.com:fog/fog.git', :branch => '8598355c6bc7a14bbefb6183de42936b1cbed3fa'
end
