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
      diff_output = diff(config_file)
      count = 0
      edge_gateway_services.each do |service|
        if diff_output[service].empty?
          count += 1
          config.delete(service) # no need to process this service
        end
      end
      unless count == edge_gateway_services.size
        edge_gateway.update_configuration config
      end
    end

    def diff(config_file)
      local_config = translate_yaml_input config_file
      edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
      diff = {}
      edge_gateway_services.each do |service|
        local = local_config[service]
        remote = remote_config[service]
        diff[service] = ( local == remote ) ? [] : HashDiff.diff(local, remote)
      end
      diff
    end

    private
    def translate_yaml_input(config_file)
      config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
      nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(config[:gateway], config[:nat_service]).generate_fog_config
      firewall_service_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(config[:firewall_service])
      out = { gateway: config[:gateway] }
      out[:FirewallService] = firewall_service_config unless firewall_service_config.nil?
      out[:NatService] = nat_service_config unless nat_service_config.nil?
      out
    end

    def edge_gateway_services
      [
        :FirewallService,
        :NatService,
      ]
    end

  end
end
