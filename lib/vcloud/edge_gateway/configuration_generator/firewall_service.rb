require 'vcloud'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      class FirewallService

        def firewall_config(input_config)
          if input_config
            firewall_service = {}
            firewall_service[:IsEnabled] = input_config.key?(:enabled) ? input_config[:enabled] : true
            firewall_service[:DefaultAction] = input_config.key?(:policy) ? input_config[:policy] : "drop"
            firewall_service[:LogDefaultAction] = input_config.key?(:log_default_action) ? input_config[:log_default_action] : false
            firewall_service[:FirewallRule] = populate_firewall_rules(input_config[:firewall_rules]) if input_config.key?(:firewall_rules)
            firewall_service
          end
        end

        private
        def populate_firewall_rules rules
          i = 1
          rules.collect do |rule|
            new_rule = {}
            new_rule[:Id] = rule.key?(:id) ? rule[:id] : i
            new_rule[:IsEnabled] = rule.key?(:enabled) ? rule[:enabled] : true
            new_rule[:MatchOnTranslate] = rule.key?(:match_on_translate) ? rule[:match_on_translate] : false
            new_rule[:Description] = rule.key?(:description) ? rule[:description] : ""
            new_rule[:Policy] = rule.key?(:policy) ? rule[:policy] : "allow"
            new_rule[:Protocols] = rule.key?(:protocols) ? handle_protocols(rule[:protocols]) : {Tcp: true}
            new_rule[:DestinationPortRange] = rule.key?(:destination_port_range) ? rule[:destination_port_range] : 'Any'
            new_rule[:DestinationIp] = rule[:destination_ip]
            new_rule[:SourcePortRange] = rule.key?(:source_port_range) ? rule[:source_port_range] : 'Any'
            new_rule[:SourceIp] = rule[:source_ip]
            new_rule[:EnableLogging] = rule.key?(:enable_logging) ? rule[:enable_logging] : false
            i += 1
            new_rule
          end
        end

        def handle_protocols(protocols)
          case protocols.downcase
            when "tcp+udp"
              {Tcp: true, Udp: true}
            when "udp"
              {Udp: true}
            when "tcp"
              {Tcp: true}
            when "icmp"
              {Icmp: true}
            when "any"
              {Tcp: true, Udp: true, Icmp: true}
          end
        end

      end
    end

  end
end
