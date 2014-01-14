#Configure edge gateway services

You can configure following services on an existing edgegateway using fog.
- FirewallService
- NatService
- LoadBalancerService

###How to configure:

```ruby
require 'fog'
vcloud = Fog::Compute::VcloudDirector.new
vcloud.post_configure_edge_gateway_services edge_gateway_id, configuration
vcloud.process_task(task.body)
```

The Configuration contain definitions of any of the services listed.Details of service configurations may vary,
but the mechanism is the same for updating any Edge Gateway service.<br/>You can include one or more services when you configure an Edge Gateway.

###Examples:

Service examples, to be used in place of the `configuration` object above.

Firewall:
```ruby
configuration = {
  :FirewallService => {
    :IsEnabled => true,
    :DefaultAction => 'allow',
    :LogDefaultAction => false,
    :FirewallRule => [
      {
        :Policy => 'allow',
        :Description => 'description',
        :Protocols => {:Tcp => true},
        :Port => 22,
        :DestinationPortRange => 22,
        :DestinationIp => 'Internal',
        :SourcePort => 22,
        :SourceIp => 'External',
        :SourcePortRange => '22'
      }
    ]
  }
}
```

Load balancer:
```ruby
configuration = {
  :LoadBalancerService => {
    :IsEnabled => "true",
    :Pool => [
      {
        :Name => 'web-app',
        :ServicePort => [
          {
            :IsEnabled => "true",
            :Protocol => "HTTP",
            :Algorithm => "ROUND_ROBIN",
            :Port => 80,
            :HealthCheckPort => 80,
            :HealthCheck => {
              :Mode => "HTTP", :HealthThreshold => 1, :UnhealthThreshold => 6, :Interval => 20, :Timeout => 25
            }
          },
          {
            :IsEnabled => true,
            :Protocol => "HTTPS",
            :Algorithm => "ROUND_ROBIN",
            :Port => 443,
            :HealthCheckPort => 443,
            :HealthCheck => {
              :Mode => "SSL", :HealthThreshold => 1, :UnhealthThreshold => 6, :Interval => 20, :Timeout => 25
            }
          }
        ],
        :Member => [
          {
            :IpAddress => "192.0.2.0",
            :Weight => 1,
            :ServicePort => [
              {:Protocol => "HTTP", :Port => 80, :HealthCheckPort => 80}
            ]
          }
        ]
      }
    ],
    :VirtualServer => [
      {
        :IsEnabled => "true",
        :Name => "app1",
        :Description => "app1",
        :Interface => {:name => "Default", :href => "https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7"},
        :IpAddress => '192.0.2.0',
        :ServiceProfile => [
          {:IsEnabled => "true", :Protocol => "HTTP", :Port => 80, :Persistence => {:Method => ""}},
          {:IsEnabled => "true", :Protocol => "HTTPS", :Port => 443, :Persistence => {:Method => ""}}
        ],
        :Logging => false,
        :Pool => 'web-app'
      }
    ]
  }
}
```

Nat:
```ruby
configuration = {
  :NatService => {
    :IsEnabled => true,
    :nat_type => 'ipTranslation',
    :Policy => 'allowTrafficIn',
    :NatRule => [
      {
        :Description => 'a snat rule',
        :RuleType => 'SNAT',
        :IsEnabled => true,
        :Id => '65538',
        :GatewayNatRule => {
          :Interface => {
            :name => 'nft00001',
            :href => 'https://vmware.api.net/api/admin/network/44265cc3-6d63-4ea9-ac72-4905b5aa6111'
            },
          :OriginalIp => "192.0.2.0",
          :TranslatedIp => "203.0.113.10"
        }
      },
      {
        :Description => 'a dnat rule',
        :RuleType => 'DNAT',
        :IsEnabled => true,
        :Id => '65539',
        :GatewayNatRule =>
        {
          :Interface => {
            :name => 'nft00001',
            :href => 'https://vmware.api.net/api/admin/network/44265cc3-6d63-4ea9-ac72-4905b5aa6111'
           },
          :Protocol => 'tcp',
          :OriginalIp => "203.0.113.10",
          :OriginalPort => 22,
          :TranslatedIp => "192.0.2.0",
          :TranslatedPort => 22
        },
      }
    ]
  }
 }
```

###Debug

Set environment variable DEBUG=true to see fog debug info.

 
