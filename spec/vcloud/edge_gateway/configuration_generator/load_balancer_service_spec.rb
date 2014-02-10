require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe LoadBalancerService do

        test_cases = [
          {
            title: 'should expand out input config into Fog expected input',
            input: {
              enabled: 'true', #opt
              pools: [
                {
                  name: 'web-app',
                  description: 'web-app',#opt
                  service: {
                    http: {
                      enabled: 'true', #opt, default true
                      algorithm: 'ROUND_ROBIN', #opt default RRB
                      port: 80, #req
                      protocol: 'HTTP', #req
                      health_check: {
                        port: '80' ,   #req
                        protocol: 'HTTP', #opt, default same as service port protocol, HTTPS => SSL
                        health_threshold: '1',  #opt default = 2
                        unhealth_threshold: '6', #opt default = 3
                        interval: '20',  #opt default 5 sec
                        timeout: '25' } #optional default 15sec
                    }
                  },
                  members: [{ ip_address: '192.168.254.100', #req
                              weight: '1', #opt default = 1, NB: 0 == 'disabled',
                            }],

                }
              ],
              virtual_servers: [
                {
                  name: 'router', #req
                  description: 'describe it', #opt
                  ip_address: '192.2.0.55', #req
                  network: 'ExternalNetwork', #req
                  pool: 'web-app', #req
                  logging: 'false', #opt, default false
                  service_profiles: {
                    http: { enabled: true, port: '80' }
                  },
                }
              ]
            },
            output: {
              :IsEnabled => "true",
              :Pool => [
                {
                  :Name => 'web-app',
                  :Description => 'web-app',
                  :ServicePort => [
                    {
                      :IsEnabled => "true",
                      :Protocol => "HTTP",
                      :Algorithm => "ROUND_ROBIN",
                      :Port => '80',
                      :HealthCheckPort => '80',
                      :HealthCheck =>
                        {
                          :Mode => "HTTP", :Uri => '', :HealthThreshold => '1', :UnhealthThreshold => '6', :Interval => '20', :Timeout => '25'
                        }
                    },
                    {
                      :IsEnabled => 'false',
                      :Protocol => "HTTPS",
                      :Algorithm => "ROUND_ROBIN",
                      :Port => '',
                      :HealthCheckPort => '',
                      :HealthCheck =>
                        {
                          :Mode => "SSL", :Uri => '', :HealthThreshold => '2', :UnhealthThreshold => '3', :Interval => '5', :Timeout => '15'
                        }
                    },
                    {
                      :IsEnabled => 'false',
                      :Protocol => "TCP",
                      :Algorithm => "ROUND_ROBIN",
                      :Port => '',
                      :HealthCheckPort => '',
                      :HealthCheck =>
                        {
                          :Mode => "TCP", :Uri => '', :HealthThreshold => '2', :UnhealthThreshold => '3', :Interval => '5', :Timeout => '15'
                        }
                    }
                  ],
                  :Member => [
                    {
                      :IpAddress => "192.168.254.100",
                      :Weight => '1',
                      :ServicePort =>
                        [
                          {:Protocol => "HTTP", :Port => '', :HealthCheckPort => ''},
                          {:Protocol => "HTTPS", :Port => '', :HealthCheckPort => ''},
                          {:Protocol => "TCP", :Port => '', :HealthCheckPort => ''},
                        ]
                    }
                  ]
                }
              ],
              :VirtualServer =>
                [
                  {
                    :IsEnabled => "true",
                    :Name => "router",
                    :Description => "describe it",
                    :Interface => {
                      name: "ExternalNetwork",
                      href: "https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012",
                      type: "application/vnd.vmware.vcloud.orgVdcNetwork+xml",
                    },
                    :IpAddress => '192.2.0.55',
                    :ServiceProfile =>
                      [
                        {
                          :IsEnabled => "true",  #default disabled opt
                          :Protocol => "HTTP", #req
                          :Port => "80", #req
                          :Persistence => {:Method => ""}  #opt default none
                        },
                        #none
                        #cookie, cookie_name & mode is manadatory
                        #ssl_session_id
                        #{:IsEnabled => "true", :Protocol => "HTTPS", :Port => 443, :Persistence => {:Method => ""}}
                        {
                          :IsEnabled => "false",  #default disabled opt
                          :Protocol => "HTTPS", #req
                          :Port => "", #req
                          :Persistence => {:Method => ""}  #opt default none
                        },
                        {
                          :IsEnabled => "false",  #default disabled opt
                          :Protocol => "TCP", #req
                          :Port => "", #req
                          :Persistence => {:Method => ""}  #opt default none
                        },
                      ],
                    :Logging => 'false', #opt false
                    :Pool => 'web-app' #req
                  }
                ]

            },
          }
        ]

        test_cases.each do |test_case|
          it "#{test_case[:title]}" do
            edge_gw_name = 'EdgeGateway1'
            edge_gw_id = '1111111-7b54-43dd-9eb1-631dd337e5a7'
            edge_gateway = double(:edge_gateway,
              :vcloud_gateway_interface_by_id => {
                Network: {
                  :name => 'ExternalNetwork',
                  :href => 'https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012'
                }
              }
            )
            expect(Vcloud::Core::EdgeGateway).
              to receive(:get_by_name).
              with(edge_gw_name).
              and_return(edge_gateway)
            generated_config = LoadBalancerService.new(edge_gw_name).
              generate_fog_config test_case[:input]
            expect(generated_config).to eq(test_case[:output])
          end
        end

      end
    end
  end
end
