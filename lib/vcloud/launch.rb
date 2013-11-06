#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'fog'
require 'json'
require 'open3'
require 'pp'
require 'vcloud/content_types'
require 'vcloud/fog_interface'
require 'vcloud/vapp'
require 'vcloud/vm'

module Vcloud
  class Launch
    def run
      fog_interface = Vcloud::FogInterface.new
      config_file = ARGV.shift
      config = load_config(config_file)

      template = fog_interface.template(config[:catalog], config[:catalog_item])

      if template.nil? 
        Vcloud.logger.fatal("Could not find template vApp. Cannot continue.")
        exit 2
      end

      config[:vapps].each do |vapp_config|
        Vcloud.logger.info("Configuring vApp #{vapp_config[:name]}.")
        Vapp.new(fog_interface).provision(
            vapp_config, config[:vdc], template
        )
      end
    end

    private
    def load_config config_file
      yaml_data = YAML::load(File.open(config_file))
      # slightly dirty hack to get our YAML data into a symbolized key hash :)
      json_string = JSON.generate(yaml_data)
      JSON.parse(json_string, :symbolize_names => true)
    end
  end
end
