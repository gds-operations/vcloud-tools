require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe LoadBalancerService do

        before(:each) do
          @edge_gw_name = 'EdgeGateway1'
          @edge_gw_id = '1111111-7b54-43dd-9eb1-631dd337e5a7'
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
            with(@edge_gw_name).
            and_return(edge_gateway)
        end

        context "top level LoadBalancer configuration defaults" do

          before(:each) do
            input = { } # minimum configuration
            @output = LoadBalancerService.new(@edge_gw_name).generate_fog_config(input)
          end

          it 'should default to LoadBalancerService enabled' do
            expect(@output[:IsEnabled]).to eq('true')
          end

          it 'should match our expected defaults' do
            expect(@output).to eq({
              :IsEnabled=>"true", :Pool=>[], :VirtualServer=>[]
            })
          end

        end

        context "When configuring a minimal VirtualServer entry" do

          before(:each) do
            input = { virtual_servers: [{
              name: "virtual-server-1",
              ip_address: '192.2.0.1',
              network: "12345678-1234-1234-1234-123456789aa",
              pool: "pool-1",
            }]}
            output = LoadBalancerService.new(@edge_gw_name).generate_fog_config(input)
            @rule = output[:VirtualServer].first
          end

          it 'should default to the entry being enabled' do
            expect(@rule[:IsEnabled]).to eq('true')
          end

          it 'should default to description being empty' do
            expect(@rule[:Description]).to eq('')
          end

          it 'should match our expected complete entry' do
            expect(@rule).to eq({
              :IsEnabled=>"true",
              :Name=>"virtual-server-1",
              :Description=>"",
              :Interface=>{
                :name=>"ExternalNetwork",
                :href=>"https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012",
                :type=>"application/vnd.vmware.vcloud.orgVdcNetwork+xml"
              },
              :IpAddress=>"192.2.0.1",
              :ServiceProfile=>[
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTP",
                  :Port=>"",
                  :Persistence=>{:Method=>""}
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTPS",
                  :Port=>"",
                  :Persistence=>{:Method=>""}
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"TCP",
                  :Port=>"",
                  :Persistence=>{:Method=>""}
                }
              ],
              :Logging=>"false",
              :Pool=>"pool-1"
            })
          end

        end

        context "When configuring a minimal Pool entry" do

          before(:each) do
            input = { pools: [{
              name: "pool-1",
              members: [ { ip_address: '10.10.10.10' } ],
            }]}
            output = LoadBalancerService.new(@edge_gw_name).generate_fog_config(input)
            @rule = output[:Pool].first
          end

          it 'should default to description being empty' do
            expect(@rule[:Description]).to eq('')
          end

          it 'should match our expected complete entry' do
            expect(@rule).to eq({
              :Name=>"pool-1",
              :Description=>"",
              :ServicePort=>[
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTP",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"HTTP",
                    :Uri=>"",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTPS",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"SSL",
                    :Uri=>"",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"TCP",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"TCP",
                    :Uri=>"",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                }],
              :Member=>[
                {
                  :IpAddress=>"10.10.10.10",
                  :Weight=>"1",
                  :ServicePort=>[
                    {:Protocol=>"HTTP",
                     :Port=>"",
                     :HealthCheckPort=>""},
                    {:Protocol=>"HTTPS",
                     :Port=>"",
                     :HealthCheckPort=>""},
                    {:Protocol=>"TCP",
                      :Port=>"",
                      :HealthCheckPort=>""}
                  ]
                }
              ]
            })
          end
        end

        context "When configuring HTTP load balancer" do

          it 'should expand out input config into Fog expected input' do
            input            = read_data_file('load_balancer_http-input.yaml')
            expected_output  = read_data_file('load_balancer_http-output.yaml')
            generated_config = LoadBalancerService.new(@edge_gw_name).
              generate_fog_config input
            expect(generated_config).to eq(expected_output)
          end

        end

        def read_data_file(name)
          full_path = File.join(File.dirname(__FILE__), 'data', name)
          unsymbolized_data = YAML::load(File.open(full_path))
          json_string = JSON.generate(unsymbolized_data)
          JSON.parse(json_string, :symbolize_names => true)
        end

      end

    end
  end
end
