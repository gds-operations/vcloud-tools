module Vcloud
  module Schema

    FIREWALL_RULE = {
        type: Hash,
        internals: {
            id: { type: 'string_or_number', required: false},
            enabled: { type: 'boolean', required: false},
            match_on_translate: { type: 'boolean', required: false},
            description: { type: 'string', required: false, allowed_empty: true},
            policy: { type: 'enum', required: false, acceptable_values: ['allow', 'drop'] },
            source_ip: { type: 'ip_address_range', required: true },
            destination_ip: { type: 'ip_address_range', required: true },
            source_port_range: { type: 'string', required: false },
            destination_port_range: { type: 'string', required: false },
            enable_logging: { type: 'boolean', required: false },
            protocols: { type: 'enum', required: false, acceptable_values: ['tcp', 'udp', 'icmp', 'tcp+udp', 'any']},
        }
    }

    FIREWALL_SERVICE = {
        type: Hash,
        allowed_empty: true,
        required: false,
        internals: {
            enabled: { type: 'boolean', required: false},
            policy: { type: 'enum', required: false, acceptable_values: ['allow', 'drop'] },
            log_default_action: { type: 'boolean', required: false},
            firewall_rules: {
                type: Array,
                required: false,
                allowed_empty: true,
                each_element_is: FIREWALL_RULE
            }
        }
    }

    EDGE_GATEWAY_SERVICES = {
        type: 'hash',
        allowed_empty: false,
        internals: {
            gateway: { type: 'string' },
            firewall_service: FIREWALL_SERVICE,
            nat_service: NAT_SERVICE
        }
    }

  end
end
