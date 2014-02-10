require 'vcloud'
require 'hashdiff'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def update(config_file = nil)
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
      local_config = { }

      edge_gateway = Core::EdgeGateway.get_by_name config[:gateway]

      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]

      firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(config[:firewall_service])

      unless firewall_service_config.nil?
        differ = EdgeGateway::ConfigurationDiffer.new(firewall_service_config, remote_config[:FirewallService])
        unless differ.diff.empty?
          local_config[:FirewallService] = firewall_service_config
        end
      end

      nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(config[:gateway], config[:nat_service]).generate_fog_config

      unless nat_service_config.nil?
        differ = EdgeGateway::ConfigurationDiffer.new(nat_service_config, remote_config[:NatService])
        unless differ.diff.empty?
          local_config[:NatService] = nat_service_config unless nat_service_config.nil?
        end
      end

      if local_config[:FirewallService].nil? and local_config[:NatService].nil?
        Vcloud.logger.info("EdgeGatewayServices.update: Configuration is already up to date. Skipping.")
      else
        edge_gateway.update_configuration local_config
      end
    end

  end
end
