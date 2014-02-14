require 'vcloud'

module Vcloud
  module EdgeGateway
    class EdgeGatewayConfiguration

      def initialize(local_config)
        @local_config = local_config
        @config = { }
      end

      def update_required?(remote_config)
        update_required = false

        firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(@local_config[:firewall_service])
        unless firewall_service_config.nil?
          differ = EdgeGateway::ConfigurationDiffer.new(firewall_service_config, remote_config[:FirewallService])
          unless differ.diff.empty?
            @config[:FirewallService] = firewall_service_config
            update_required = true
          end
        end

        nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(@local_config[:gateway], @local_config[:nat_service]).generate_fog_config

        unless nat_service_config.nil?
          differ = EdgeGateway::ConfigurationDiffer.new(nat_service_config, remote_config[:NatService])
          unless differ.diff.empty?
            @config[:NatService] = nat_service_config
            update_required = true
          end
        end

        update_required
      end

      def config
        @config
      end

    end
  end
end
