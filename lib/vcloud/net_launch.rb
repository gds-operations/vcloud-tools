require 'fog'
require 'vcloud'

module Vcloud
  class NetLaunch

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def run(config_file = nil, options = {})
      config = @config_loader.load_config(config_file)

      if options[:mock] || ENV['FOG_MOCK']
        ::Fog.mock!
      end

      config[:org_vdc_networks].each do |net_config|
        net_config[:fence_mode] ||= 'isolated'
        Vcloud.logger.info("Provisioning orgVdcNetwork #{net_config[:name]}.")
        begin
          net = Vcloud::Core::OrgVdcNetwork.provision(net_config)
        rescue RuntimeError => e
          Vcloud.logger.error("Could not provision orgVdcNetwork: #{e.message}")
          raise
        end
      end
    end

  end
end
