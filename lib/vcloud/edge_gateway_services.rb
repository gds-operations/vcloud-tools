require 'vcloud'
require 'hashdiff'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def update(config_file = nil)
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)

      edge_gateway = Core::EdgeGateway.get_by_name config[:gateway]
      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]

      proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(config)

      if proposed_config.update_required?(remote_config)
        edge_gateway.update_configuration proposed_config.config
      else
        Vcloud.logger.info("EdgeGatewayServices.update: Configuration is already up to date. Skipping.")
      end
    end

  end
end
