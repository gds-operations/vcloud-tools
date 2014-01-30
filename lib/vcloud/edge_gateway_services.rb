require 'vcloud'
require 'hashdiff'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def update(config_file = nil, options = {})
      config = translate_yaml_input(config_file)
      edge_gateway = Core::EdgeGateway.get_by_name config[:gateway]

      unless diff(config_file).empty?
        edge_gateway.update_configuration config
      end
    end

    def diff(config_file)
      local_config = translate_yaml_input config_file
      edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
      return [] if local_config[:FirewallService] == remote_config
      HashDiff.diff(local_config[:FirewallService], remote_config)
    end

    private
    def translate_yaml_input(config_file)
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
      nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(config[:gateway], config[:nat_service]).generate_fog_config
      firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(config[:firewall_service])
      {
        :gateway => config[:gateway],
        :FirewallService => firewall_service_config,
        :NatService => nat_service_config
      }
    end

  end
end

