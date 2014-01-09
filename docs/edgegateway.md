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

Examples for configuring different services:

firewall => https://gist.github.com/snehaso/cd839ac05c640b954bed

load-balancer => https://gist.github.com/snehaso/20c080d0ec0ba7a00611

nat => https://gist.github.com/snehaso/e5ae5767fe1ac2e4e98d

###Debug

Set environment variable DEBUG=true to see fog debug info.

 
