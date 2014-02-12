require 'vcloud'

module Vcloud
  module EdgeGateway
    class EdgeGatewayConfiguration

      def initialize(local_config)
        @local_config = local_config
      end

      def update_required?(remote_config)
        true
      end

      def config
        config = { }

        firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(@local_config[:firewall_service])
        config[:FirewallService] = firewall_service_config unless firewall_service_config.nil?

        nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(@local_config[:gateway], @local_config[:nat_service]).generate_fog_config
        config[:NatService] = nat_service_config unless nat_service_config.nil?

        config
      end

    end
  end
end
