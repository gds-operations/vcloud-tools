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
require 'vcloud/schema/firewall_service'
require 'vcloud/schema/load_balancer_service'
require 'vcloud/schema/edge_gateway'
require 'vcloud/edge_gateway/configuration_generator/id_ranges'
require 'vcloud/edge_gateway/configuration_generator/firewall_service'
require 'vcloud/edge_gateway/configuration_generator/nat_service'
require 'vcloud/edge_gateway/configuration_generator/load_balancer_service'
require 'vcloud/edge_gateway/configuration_differ'
require 'vcloud/edge_gateway/load_balancer_configuration_differ'
require 'vcloud/edge_gateway/edge_gateway_configuration'

module Vcloud

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.clone_object object
    Marshal.load(Marshal.dump(object))
  end

end
