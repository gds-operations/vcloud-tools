module Vcloud
  module EdgeGateway
    module ConfigurationGenerator

      class NatService
        def generate_fog_config input_config
          if input_config
            nat_service = {}
            nat_service[:IsEnabled] = input_config.key?(:enabled) ? input_config[:enabled].to_s : 'true'
            nat_service[:NatRule] = populate_nat_rules(input_config[:nat_rules])
            nat_service
          end
          nat_service
        end

        def populate_nat_rules(rules)
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
          network_attrs = Vcloud::Core::OrgVdcNetwork.get_by_name(rule[:network]).vcloud_attributes
          gateway_nat_rule = {:Interface => {:name => network_attrs[:name], :href => network_attrs[:href] }}
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
