module Vcloud
  module Schema

    NAT_RULE = {
      type: Hash,
      internals: {
        id: {type: 'string_or_number', required: false},
        enabled: {type: 'boolean', required: false},
        rule_type: { type: 'enum', required: true, acceptable_values: ['SNAT', 'DNAT' ]},
        description: {type: 'string', required: false, allowed_empty: true},
        network: {type: 'string', required: true},
        original_ip: {type: 'ip_address', required: true},
        original_port: {type: 'string', required: false},
        translated_ip: {type: 'ip_address', required: true},
        translated_port: {type: 'string', required: false},
        protocol: {type: 'enum', required: false, acceptable_values: ['tcp', 'udp', 'icmp', 'tcp+udp', 'any']},
      }
    }

    NAT_SERVICE = {
      type: Hash,
      allowed_empty: true,
      internals: {
        enabled: {type: 'boolean', required: false},
        nat_rules: {
          type: Array,
          required: false,
          allowed_empty: true,
          each_element_is: NAT_RULE
        }
      }
    }
  end
end
