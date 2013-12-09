require 'rubygems'
require 'bundler/setup'
require 'fog'
require 'json'
require 'yaml'
require 'csv'
require 'open3'
require 'pp'

require 'vcloud/version'
require 'vcloud/entity'
require 'vcloud/launch'
require 'vcloud/query'
require 'vcloud/constants'
require 'vcloud/content_types'
require 'vcloud/relation'
require 'vcloud/fog_service_interface'
require 'vcloud/fog_model_interface'
require 'vcloud/vm_orchestrator'
require 'vcloud/vapp'
require 'vcloud/vm'
require 'vcloud/config_loader'
require 'vcloud/vapp_template'

module Vcloud

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.clone_object object
    Marshal.load(Marshal.dump(object))
  end

end
