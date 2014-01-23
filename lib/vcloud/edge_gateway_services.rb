require 'vcloud'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def update(config_file = nil, options = {})
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
      firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.firewall_config(config[:firewall_service])
      edge_gateway = Core::EdgeGateway.get_by_name config[:gateway]

      edge_gateway.update_configuration({:FirewallService => firewall_service_config})
    end

    def diff(config_file)

    end

  end
end
