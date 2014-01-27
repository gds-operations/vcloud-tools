require 'rubygems'
require 'bundler/setup'
require 'json'
require 'yaml'
require 'csv'
require 'open3'
require 'pp'

require 'vcloud/version'

require 'vcloud/fog'
require 'vcloud/core'

require 'vcloud/config_loader'
require 'vcloud/config_validator'
require 'vcloud/launch'
require 'vcloud/net_launch'
require 'vcloud/vm_orchestrator'
require 'vcloud/vapp_orchestrator'

require 'vcloud/edge_gateway_services'
require 'vcloud/schema/nat_service'
require 'vcloud/schema/edge_gateway'
Dir["#{File.dirname(__FILE__)}/vcloud/edge_gateway/configuration_generator/*.rb"].each {|file| require file }

module Vcloud

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.clone_object object
    Marshal.load(Marshal.dump(object))
  end

end
