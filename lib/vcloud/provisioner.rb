#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'fog'
require_relative 'fog_interface'
require_relative '../provisioner/vapp'
require_relative '../provisioner/vm'

module Vcloud
  class Provisioner
    def run
      fog_interface = FogInterface.new
      data = load_config
      template = fog_interface.template(data['catalog'], data['catalog_item'])

      data["vapps"].each do |vapp_config|
        Provisioner::Vapp.new(fog_interface).provision(
            vapp_config, data['vdc'], template
        )
      end
    end

    private
    def load_config
      YAML::load(File.open("#{File.dirname(__FILE__)}/../data/carrenza.yaml"))
    end
  end
end







