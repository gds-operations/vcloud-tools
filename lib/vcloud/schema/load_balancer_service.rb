module Vcloud
  module Schema

    LOAD_BALANCER_MEMBER_ENTRY = {
      type: Hash,
      internals: {
        ip_address: { type: 'ip_address', required: true },
        weight:     { type: 'string_or_number', required: false },
      }
    }

    LOAD_BALANCER_POOL_ENTRY = {
      type: Hash,
      internals: {
        name: { type: 'string', required: true },
        description: { type: 'string', required: false },
        members: {
          type: Array,
          required: true,
          allowed_empty: false,
          each_element_is: LOAD_BALANCER_MEMBER_ENTRY,
        }
      }
    }

    LOAD_BALANCER_VIRTUAL_SERVER_ENTRY = {
      type: Hash,
      internals: {
        enabled: { type: 'boolean', required: false },
        name:    { type: 'string', required: true },
        description: { type: 'string', required: false },
        ip_address: { type: 'ip_address', required: true },
        network: { type: 'string', required: true },
        pool: { type: 'string', required: true },
      }
    }

    LOAD_BALANCER_SERVICE = {
      type: Hash,
      allowed_empty: true,
      internals: {
        enabled: { type: 'boolean', required: false },
        pools: {
          type: Array,
          required: true,
          allowed_empty: true,
          each_element_is: LOAD_BALANCER_POOL_ENTRY,
        },
        virtual_servers: {
          type: Array,
          required: true,
          allowed_empty: true,
          each_element_is: LOAD_BALANCER_VIRTUAL_SERVER_ENTRY,
        },
      }
    }
  end
end
