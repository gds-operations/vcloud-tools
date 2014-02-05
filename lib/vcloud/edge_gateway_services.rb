require 'vcloud'
require 'hashdiff'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def self.edge_gateway_services
      [
        :FirewallService,
        :NatService,
      ]
    end

    def update(config_file = nil, options = {})
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
      nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(config[:gateway], config[:nat_service]).generate_fog_config
      firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(config[:firewall_service])

      local_config = { gateway: config[:gateway] }
      local_config[:FirewallService] = firewall_service_config unless firewall_service_config.nil?
      local_config[:NatService] = nat_service_config unless nat_service_config.nil?

      edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
      diff_output = {}

      skipped_service_count = 0
      EdgeGatewayServices.edge_gateway_services.each do |service|
        local = local_config[service]
        remote = remote_config[service]
        differ = EdgeGateway::ConfigurationDiffer.new(local, remote)
        diff_output[service] = differ.diff

        if diff_output[service].empty? or not local_config.key?(service)
          skipped_service_count += 1
          local_config.delete(service)
        end
      end

      if skipped_service_count == EdgeGatewayServices.edge_gateway_services.size
        Vcloud.logger.info("EdgeGatewayServices.update: Configuration is already up to date. Skipping.")
      else
        edge_gateway.update_configuration local_config
      end
    end

  end
end
