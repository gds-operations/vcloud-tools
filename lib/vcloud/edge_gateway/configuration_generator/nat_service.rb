module Vcloud
  module EdgeGateway
    module ConfigurationGenerator

      class NatService
        def initialize edge_gateway, input_config
          @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(edge_gateway)
          @input_config = input_config
        end

        def generate_fog_config
          if @input_config
            nat_service = {}
            nat_service[:IsEnabled] = @input_config.key?(:enabled) ? @input_config[:enabled].to_s : 'true'
            nat_service[:NatRule] = populate_nat_rules
            nat_service
          end
        end

        def populate_nat_rules
          rules = @input_config[:nat_rules]
            i = ID_RANGES::NAT_SERVICE[:min]
            rules.collect do |rule|
              new_rule = {}
              new_rule[:Id] = rule.key?(:id) ? rule[:id] : i.to_s
              new_rule[:IsEnabled] = rule.key?(:enabled) ? rule[:enabled].to_s : 'true'
              new_rule[:RuleType] = rule[:rule_type]
              new_rule[:Description] = rule.key?(:description) ? rule[:description] : ""
              gateway_nat_rule = populate_gateway_nat_rule(rule)
              new_rule[:GatewayNatRule] = gateway_nat_rule
              i += 1
              new_rule
          end
        end

        def populate_gateway_nat_rule(rule)
          gateway_interface = @edge_gateway.vcloud_gateway_interface_by_id(rule[:network_id])
          raise "unable to find gateway network interface with id #{rule[:network_id]}" unless gateway_interface
          gateway_nat_rule = {:Interface => gateway_interface[:Network]}
          gateway_nat_rule[:OriginalIp] = rule[:original_ip]
          gateway_nat_rule[:TranslatedIp] = rule[:translated_ip]
          gateway_nat_rule[:OriginalPort] = rule[:original_port] if rule.key?(:original_port)
          gateway_nat_rule[:TranslatedPort] = rule[:translated_port] if rule.key?(:translated_port)
          gateway_nat_rule[:Protocol] = rule.key?(:Protocol) ? rule[:Protocol] : "tcp"
          gateway_nat_rule
        end

      end
    end
  end
end
