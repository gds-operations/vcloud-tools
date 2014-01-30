require 'spec_helper'

module Vcloud
  describe EdgeGatewayServices do
    it "raise exception if input yaml does not match with schema" do
      config_yaml = File.expand_path('data/incorrect_firewall_config.yaml', File.dirname(__FILE__))
      expect { EdgeGatewayServices.new.update(config_yaml) }.to raise_error('Supplied configuration does not match supplied schema')
    end

    context "#configure_edge_gateway_services" do
      before(:all) do
        reset_edge_gateway
      end

      it "should configure firewall service" do
        config_erb = File.expand_path('data/firewall_config.yaml.erb', File.dirname(__FILE__))
        input_config_file = generate_input_yaml_config({:edge_gateway_name => ENV['VCLOUD_EDGE_GATEWAY']}, config_erb)
        EdgeGatewayServices.new.update(input_config_file)

        edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(ENV['VCLOUD_EDGE_GATEWAY'])

        firewall_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
        expect(firewall_service.key?(:FirewallRule)).to be_true
        expect(firewall_service[:FirewallRule]).to eq([{:Id => "1",
                                                        :IsEnabled => "true",
                                                        :MatchOnTranslate => "false",
                                                        :Description => "A rule",
                                                        :Policy => "allow",
                                                        :Protocols => {:Tcp => "true"},
                                                        :Port => "-1",
                                                        :DestinationPortRange => "Any",
                                                        :DestinationIp => "10.10.1.2",
                                                        :SourcePort => "-1",
                                                        :SourcePortRange => "Any",
                                                        :SourceIp => "192.0.2.2",
                                                        :EnableLogging => "false"}])

        File.delete(input_config_file)
      end

      it "should not configure the firewall service if updated again with the same configuration (idempotency)" do
        obj = EdgeGatewayServices.new
        config_erb = File.expand_path('data/firewall_config.yaml.erb', File.dirname(__FILE__))
        input_config_file = generate_input_yaml_config({:edge_gateway_name => ENV['VCLOUD_EDGE_GATEWAY']}, config_erb)
        expect(Core::EdgeGateway).to receive(:update_configuration).at_most(0).times
        EdgeGatewayServices.new.update(input_config_file)
        File.delete(input_config_file)
      end

      context "validate the diff against our intended configuration" do
        it "return empty if both configs match " do
          config_erb = File.expand_path('data/firewall_config.yaml.erb', File.dirname(__FILE__))
          input_config_file = generate_input_yaml_config({:edge_gateway_name => ENV['VCLOUD_EDGE_GATEWAY']}, config_erb)
          diff_output = EdgeGatewayServices.new.diff(input_config_file)
          expect(diff_output).to eq([])

          File.delete(input_config_file)
        end

        it "return show diff if local firewall config has different ip and port " do
          config_erb = File.expand_path('data/firewall_config_1.yaml.erb', File.dirname(__FILE__))
          input_config_file = generate_input_yaml_config({:edge_gateway_name => ENV['VCLOUD_EDGE_GATEWAY']}, config_erb)
          diff_output = EdgeGatewayServices.new.diff(input_config_file)
          pp diff_output
          expect(diff_output.size).to eq(2)

          File.delete(input_config_file)
        end
      end

      context "configure nat service" do

        it "configure DNAT rule with provider network" do
          config_erb = File.expand_path('data/nat_config.yaml.erb', File.dirname(__FILE__))
          input_config_file = generate_input_yaml_config({edge_gateway_name: ENV['VCLOUD_EDGE_GATEWAY'],
                                                          network_id: ENV['VCLOUD_PROVIDER_NETWORK_ID'],
                                                          original_ip: ENV['VCLOUD_PROVIDER_NETWORK_IP']
                                                         }, config_erb)

          EdgeGatewayServices.new.update(input_config_file)

          edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(ENV['VCLOUD_EDGE_GATEWAY'])
          nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expected_rule = nat_service[:NatRule].first
          expect(expected_rule).not_to be_nil
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:Id]).to eq('65537')
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:IsEnabled]).to eq('true')
          expect(expected_rule[:GatewayNatRule][:Interface][:href]).to include(ENV['VCLOUD_PROVIDER_NETWORK_ID'])
          expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(ENV['VCLOUD_PROVIDER_NETWORK_IP'])
          expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
          expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')

          File.delete(input_config_file)
        end

        it "configure hairpin NATting with orgVdcNetwork" do
          config_erb = File.expand_path('data/nat_config.yaml.erb', File.dirname(__FILE__))
          input_config_file = generate_input_yaml_config({edge_gateway_name: ENV['VCLOUD_EDGE_GATEWAY'],
                                                          network_id: ENV['VCLOUD_NETWORK1_ID'],
                                                          original_ip: ENV['VCLOUD_NETWORK1_IP']
                                                         }, config_erb)

          EdgeGatewayServices.new.update(input_config_file)

          edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(ENV['VCLOUD_EDGE_GATEWAY'])
          nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expected_rule = nat_service[:NatRule].first
          expect(expected_rule).not_to be_nil
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:Id]).to eq('65537')
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:IsEnabled]).to eq('true')
          expect(expected_rule[:GatewayNatRule][:Interface][:name]).to eq(ENV['VCLOUD_NETWORK1_NAME'])
          expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(ENV['VCLOUD_NETWORK1_IP'])
          expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
          expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')

          File.delete(input_config_file)
        end

        it "should raise error if network provided in rule does not exist" do
          config_erb = File.expand_path('data/nat_config.yaml.erb', File.dirname(__FILE__))
          random_network_id = SecureRandom.uuid
          input_config_file = generate_input_yaml_config({edge_gateway_name: ENV['VCLOUD_EDGE_GATEWAY'],
                                                          network_id: random_network_id,
                                                          original_ip: ENV['VCLOUD_NETWORK1_IP']
                                                         }, config_erb)

          expect{EdgeGatewayServices.new.update(input_config_file)}.to raise_error("unable to find gateway network interface with id #{random_network_id}")
          File.delete(input_config_file)
        end
      end

      after(:all) do
        reset_edge_gateway
      end
    end

    def reset_edge_gateway
      edge_gateway = Core::EdgeGateway.get_by_name ENV['VCLOUD_EDGE_GATEWAY']
      edge_gateway.update_configuration({
                                          FirewallService: {IsEnabled: false, FirewallRule: []},
                                          NatService: {:IsEnabled => "true", :NatRule => []},
                                          LoadBalancerService: {
                                            IsEnabled: "false",
                                            Pool: [],
                                            VirtualServer: []
                                          }
                                        })
    end

    def generate_input_yaml_config test_namespace, input_erb_config
      input_erb_config = input_erb_config
      e = ERB.new(File.open(input_erb_config).read)
      output_yaml_config = File.join(File.dirname(input_erb_config), "output_#{Time.now.strftime('%s')}.yaml")
      File.open(output_yaml_config, 'w') { |f|
        f.write e.result(OpenStruct.new(test_namespace).instance_eval { binding })
      }
      output_yaml_config
    end
  end
end
