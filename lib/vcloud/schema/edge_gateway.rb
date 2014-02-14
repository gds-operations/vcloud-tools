module Vcloud
  module Schema

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
