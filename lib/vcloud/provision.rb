#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'fog'
require 'json'
require 'open3'
require 'pp'
require_relative 'content_types'
require_relative 'fog_interface'
require_relative '../provisioner/vapp'
require_relative '../provisioner/vm'

module Vcloud
  class Provision
    def run
      fog_interface = FogInterface.new
      config_file = ARGV.shift
      config = load_config(config_file)
      template = fog_interface.template(config[:catalog], config[:catalog_item])

      config[:vapps].each do |vapp_config|
        VCloud.logger.info("Configuring vApp #{vapp_config[:name]}.")
        Provisioner::Vapp.new(fog_interface).provision(
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







