#Configure edge gateway services

You can configure following services on an existing edgegateway using fog.
- FirewallService
- NatService
- LoadBalancerService

###How to configure:

<pre>
vcloud = Fog::Compute::VcloudDirector.new
vcloud.post_configure_edge_gateway_services edge_gateway_id, configuration
</pre>

The Configuration contain definitions of any of the services listed.Details of service configurations may vary,
but the mechanism is the same for updating any Edge Gateway service.<br/>You can include one or more services when you configure an Edge Gateway.


###Debug

Set environment variable DEBUG=true to see fog debug info.

 
