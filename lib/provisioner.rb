#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'fog'
require_relative 'provision/vapp'
require_relative 'provision/vm'
require_relative 'provision/fog_interface'
require_relative 'provision/types'


class Provisioner
  def run
    fog_interface = FogInterface.new
    template = fog_interface.template(data['catalog'], data['catalog_item'])
    data = load_config
    data["vapps"].each do |machine|
      Provision::Vapp.new(fog_interface).provision(
          machine, data['vdc'], template
      )
    end
  end

  private
  def load_config
    YAML::load(File.open("#{File.dirname(__FILE__)}/../data/carrenza.yaml"))
  end
end







