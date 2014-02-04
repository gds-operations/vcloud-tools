require 'spec_helper'

module Vcloud
  describe EdgeGatewayServices do

    required_env = {
      'VCLOUD_EDGE_GATEWAY' => 'to name of VSE',
      'VCLOUD_PROVIDER_NETWORK_ID' => 'to ID of VSE external network',
      'VCLOUD_PROVIDER_NETWORK_IP' => 'to an available IP on VSE external network',
      'VCLOUD_NETWORK1_ID' => 'to the ID of a VSE internal network',
      'VCLOUD_NETWORK1_NAME' => 'to the name of the VSE internal network',
      'VCLOUD_NETWORK1_IP' => 'to an ID on the VSE internal network',
    }

    error = false
    required_env.each do |var,message|
      unless ENV[var]
        puts "Must set #{var} #{message}" unless ENV[var]
        error = true
      end
    end
    Kernel.exit(2) if error

    before(:all) do
      @edge_name = ENV['VCLOUD_EDGE_GATEWAY']
      @ext_net_id = ENV['VCLOUD_PROVIDER_NETWORK_ID']
      @ext_net_ip = ENV['VCLOUD_PROVIDER_NETWORK_IP']
      @ext_net_name = ENV['VCLOUD_PROVIDER_NETWORK_NAME']
      @int_net_id = ENV['VCLOUD_NETWORK1_ID']
      @int_net_ip = ENV['VCLOUD_NETWORK1_IP']
      @int_net_name = ENV['VCLOUD_NETWORK1_NAME']
      @files_to_delete = []
    end

    it "raise exception if input yaml does not match with schema" do
      config_yaml = File.expand_path('data/incorrect_firewall_config.yaml', File.dirname(__FILE__))
      expect(Vcloud.logger).to receive(:fatal)
      expect { EdgeGatewayServices.new.update(config_yaml) }.to raise_error('Supplied configuration does not match supplied schema')
    end

    context "#configure_edge_gateway_services" do
      before(:all) do
        reset_edge_gateway
        @initial_firewall_config_file = generate_input_config_file('firewall_config.yaml.erb', edge_gateway_erb_input)
      end

      it "should configure an initial firewall service" do
        EdgeGatewayServices.new.update(@initial_firewall_config_file)

        edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)

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
      end

      it "and then should not configure the firewall service if updated again with the same configuration (idempotency)" do
        expect(Core::EdgeGateway).to receive(:update_configuration).at_most(0).times
        EdgeGatewayServices.new.update(@initial_firewall_config_file)
      end

      it "and so diff should return empty if both configs match" do
        diff_output = EdgeGatewayServices.new.diff(@initial_firewall_config_file)
        expect(diff_output[:FirewallService]).to eq([])
      end

      it "return show diff if local firewall config has different ip and port " do
        input_config_file = generate_input_config_file('firewall_config_updated_rule.yaml.erb', edge_gateway_erb_input)
        diff_output = EdgeGatewayServices.new.diff(input_config_file)
        expect(diff_output[:FirewallService].size).to eq(2)
      end

      it "and then should configure DNAT rule with provider network" do
        input_config_file = generate_input_config_file('nat_config.yaml.erb', {
          edge_gateway_name: @edge_name,
          network_id: @ext_net_id,
          original_ip: @ext_net_ip,
        })

        EdgeGatewayServices.new.update(input_config_file)

        edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
        nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
        expected_rule = nat_service[:NatRule].first
        expect(expected_rule).not_to be_nil
        expect(expected_rule[:RuleType]).to eq('DNAT')
        expect(expected_rule[:Id]).to eq('65537')
        expect(expected_rule[:RuleType]).to eq('DNAT')
        expect(expected_rule[:IsEnabled]).to eq('true')
        expect(expected_rule[:GatewayNatRule][:Interface][:href]).to include(@ext_net_id)
        expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(@ext_net_ip,)
        expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
        expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
        expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
        expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
      end

      it "and then should configure hairpin NATting with orgVdcNetwork" do
        input_config_file = generate_input_config_file('nat_config.yaml.erb', {
          edge_gateway_name: @edge_name,
          network_id: @int_net_id,
          original_ip: @int_net_ip,
        })

        EdgeGatewayServices.new.update(input_config_file)

        edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
        nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
        expected_rule = nat_service[:NatRule].first
        expect(expected_rule).not_to be_nil
        expect(expected_rule[:RuleType]).to eq('DNAT')
        expect(expected_rule[:Id]).to eq('65537')
        expect(expected_rule[:RuleType]).to eq('DNAT')
        expect(expected_rule[:IsEnabled]).to eq('true')
        expect(expected_rule[:GatewayNatRule][:Interface][:name]).to eq(@int_net_name)
        expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(@int_net_ip)
        expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
        expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
        expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
        expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
      end

      it "should raise error if network provided in rule does not exist" do
        random_network_id = SecureRandom.uuid
        input_config_file = generate_input_config_file('nat_config.yaml.erb', {
          edge_gateway_name: @edge_name,
          network_id: random_network_id,
          original_ip: @int_net_ip,
        })
        expect{EdgeGatewayServices.new.update(input_config_file)}.
          to raise_error("unable to find gateway network interface with id #{random_network_id}")
      end

      after(:all) do
        reset_edge_gateway
      end
    end

    after(:all) do
      remove_temp_config_files
    end

    def remove_temp_config_files
      FileUtils.rm(@files_to_delete)
    end

    def reset_edge_gateway
      edge_gateway = Core::EdgeGateway.get_by_name @edge_name
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

    def generate_input_config_file(data_file, erb_input)
      config_erb = File.expand_path("data/#{data_file}", File.dirname(__FILE__))
      generate_input_yaml_config(erb_input, config_erb)
    end

    def generate_input_yaml_config test_namespace, input_erb_config
      e = ERB.new(File.open(input_erb_config).read)
      basename = File.basename(input_erb_config).gsub(/\.erb$/, '')
      output_yaml_config = File.join(File.dirname(input_erb_config), "output_#{basename}_#{Time.now.strftime('%s.%6N')}.yaml")
      File.open(output_yaml_config, 'w') { |f|
        f.write e.result(OpenStruct.new(test_namespace).instance_eval { binding })
      }
      @files_to_delete << output_yaml_config
      output_yaml_config
    end

    def edge_gateway_erb_input
      {
        :edge_gateway_name => @edge_name,
        :edge_gateway_ext_network_id => @ext_net_id,
        :edge_gateway_ext_network_ip => @ext_net_ip,
      }
    end

  end
end
