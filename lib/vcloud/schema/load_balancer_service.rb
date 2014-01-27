module Vcloud
  module Schema

    POOL_MEMBER_SERVICE_PORT_ENTRY = {
      type: Hash,
      required: false,
      internals: {
        port: { type: 'string_or_number', required: false },
        health_check_port: { type: 'string_or_number', required: false },
      }
    }

    LOAD_BALANCER_MEMBER_ENTRY = {
      type: Hash,
      internals: {
        ip_address: { type: 'ip_address', required: true },
        weight:     { type: 'string_or_number', required: false },
        service_port: {
          type: 'hash',
          required: false,
          internals: {
            http:  POOL_MEMBER_SERVICE_PORT_ENTRY,
            https: POOL_MEMBER_SERVICE_PORT_ENTRY,
            tcp:   POOL_MEMBER_SERVICE_PORT_ENTRY,
          },
        },
      },
    }

    POOL_SERVICE_SECTION = {
      type: Hash,
      required: false,
      internals: {
        enabled: { type: 'boolean', required: false },
        port:    { type: 'string_or_number', required: false },
        algorithm: { type: 'enum', required: false,
          acceptable_values: [ 'ROUND_ROBIN', 'IP_HASH', 'URI', 'LEAST_CONNECTED' ]},
        health_check: {
          type: 'hash',
          required: false,
          internals: {
            port: { type: 'string_or_number', required: false },
            protocol: { type: 'enum', required: false,
              acceptable_values: [ 'HTTP', 'SSL', 'TCP' ] },
            health_threshold: { type: 'string_or_number', required: false },
            unhealth_threshold: { type: 'string_or_number', required: false },
            interval: { type: 'string_or_number', required: false },
            timeout: { type: 'string_or_number', required: false },
          },
        },
      }
    }

    LOAD_BALANCER_POOL_ENTRY = {
      type: Hash,
      internals: {
        name: { type: 'string', required: true },
        description: { type: 'string', required: false },
        service: {
          type: 'hash',
          required: false,
          internals: {
            http:  POOL_SERVICE_SECTION,
            https: POOL_SERVICE_SECTION,
            tcp:   POOL_SERVICE_SECTION,
          }
        },
        members: {
          type: Array,
          required: true,
          allowed_empty: false,
          each_element_is: LOAD_BALANCER_MEMBER_ENTRY,
        }
      }
    }

    VIRTUAL_SERVER_SERVICE_PROFILE_ENTRY = {
      type: Hash,
      required: false,
      internals: {
        enabled: { type: 'boolean', required: false },
        port: { type: 'string_or_number', required: false },
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
        logging: { type: 'boolean', required: false },
        service_profiles: {
          type: 'hash',
          required: false,
          internals: {
            http:  VIRTUAL_SERVER_SERVICE_PROFILE_ENTRY,
            https: VIRTUAL_SERVER_SERVICE_PROFILE_ENTRY,
            tcp:   VIRTUAL_SERVER_SERVICE_PROFILE_ENTRY,
          },
        },
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
