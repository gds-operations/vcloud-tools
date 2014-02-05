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
        @initial_nat_config_file = generate_input_config_file(
          'nat_config.yaml.erb', {
              edge_gateway_name: @edge_name,
              network_id: @ext_net_id,
              original_ip: @ext_net_ip,
            }
          )
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
        @firewall_service = {}
      end

      it "should configure an initial firewall service" do
        expect_any_instance_of(Core::EdgeGateway).to receive(:update_configuration).exactly(1).times.and_call_original
        expect(EdgeGatewayServices.new.update(@initial_firewall_config_file)).to be_true
      end

      context "ensure EdgeGateway FirewallService configuration is as expected" do
        before(:all) do
          @firewall_service = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
        end

        it "should configure multiple firewall rules" do
          expect(@firewall_service.key?(:FirewallRule)).to be_true
          expect(@firewall_service[:FirewallRule].count).to eq(2)
        end

        it "should configure firewall rule with destination and source ip addresses" do
          expect(@firewall_service[:FirewallRule].first).to eq({:Id => "1",
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
                                                                :EnableLogging => "false"})
        end

        it "should configure firewall rule with destination and source ip ranges" do
          expect(@firewall_service[:FirewallRule].last).to eq({:Id => "2",
                                                               :IsEnabled => "true",
                                                               :MatchOnTranslate => "false",
                                                               :Description => "",
                                                               :Policy => "allow",
                                                               :Protocols => {:Tcp => "true"},
                                                               :Port => "-1",
                                                               :DestinationPortRange => "Any",
                                                               :DestinationIp => "10.10.1.3-10.10.1.5",
                                                               :SourcePort => "-1",
                                                               :SourcePortRange => "Any",
                                                               :SourceIp => "192.0.2.2/24",
                                                               :EnableLogging => "false"})
        end

      end

      it "and then should not configure the firewall service if updated again with the same configuration (idempotency)" do
        expect(Vcloud.logger).to receive(:info).with('EdgeGatewayServices.update: Configuration is already up to date. Skipping.')
        EdgeGatewayServices.new.update(@initial_firewall_config_file)
      end

      it "and so diff should return empty if local and remote firewall configs match" do
        edge_gateway_service = EdgeGatewayServices.new
        local_config = edge_gateway_service.translate_yaml_input(@initial_firewall_config_file)
        edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
        remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]

        local_firewall_config = local_config[:FirewallService]
        remote_firewall_config = remote_config[:FirewallService]

        differ = EdgeGateway::ConfigurationDiffer.new(local_firewall_config, remote_firewall_config)
        diff_output = differ.diff

        expect(diff_output).to eq([])
      end

      it "return show diff if local firewall config has different ip and port " do
        input_config_file = generate_input_config_file('firewall_config_updated_rule.yaml.erb', edge_gateway_erb_input)

        edge_gateway_service = EdgeGatewayServices.new
        local_config = edge_gateway_service.translate_yaml_input(input_config_file)
        edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
        remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]

        local_firewall_config = local_config[:FirewallService]
        remote_firewall_config = remote_config[:FirewallService]

        differ = EdgeGateway::ConfigurationDiffer.new(local_firewall_config, remote_firewall_config)
        diff_output = differ.diff

        expect(diff_output.size).to eq(3)
      end

      it "and then should configure NatService" do
        expect(EdgeGatewayServices.new.update(@initial_nat_config_file)).to be_true
      end

      context "ensure updated EdgeGateway NatService configuration is as expected" do
        before(:all) do
          @nat_service = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
        end

        it "should configure DNAT rule" do
          dnat_rule = @nat_service[:NatRule].first
          expect(dnat_rule).not_to be_nil
          expect(dnat_rule[:RuleType]).to eq('DNAT')
          expect(dnat_rule[:Id]).to eq('65537')
          expect(dnat_rule[:IsEnabled]).to eq('true')
          expect(dnat_rule[:GatewayNatRule][:Interface][:href]).to include(@ext_net_id)
          expect(dnat_rule[:GatewayNatRule][:OriginalIp]).to eq(@ext_net_ip)
          expect(dnat_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2-10.10.1.3')
          expect(dnat_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
        end

        it "should configure SNAT rule" do
          snat_rule = @nat_service[:NatRule].last
          expect(snat_rule).not_to be_nil
          expect(snat_rule[:RuleType]).to eq('SNAT')
          expect(snat_rule[:Id]).to eq('65538')
          expect(snat_rule[:IsEnabled]).to eq('true')
          expect(snat_rule[:GatewayNatRule][:Interface][:href]).to include(@ext_net_id)
          expect(snat_rule[:GatewayNatRule][:OriginalIp]).to eq('10.10.1.2-10.10.1.3')
          expect(snat_rule[:GatewayNatRule][:TranslatedIp]).to eq(@ext_net_ip)
        end

      end

      #it "and then should not configure the NAT service if updated again with the same configuration (idempotency)" do
      #  expect(Vcloud.logger).to receive(:info).with('EdgeGatewayServices.update: Configuration is already up to date. Skipping.')
      #  EdgeGatewayServices.new.update(@initial_nat_config_file)
      #end

      #it "and so NatService diff should return empty if both configs match" do
      #  diff_output = EdgeGatewayServices.new.diff(@initial_nat_config_file)
      #  expect(diff_output[:NatService]).to eq([])
      #end

      context "ensure hairpin NAT rules are specifiable" do

        it "and then should configure hairpin NATting with orgVdcNetwork" do
          input_config_file = generate_input_config_file('hairpin_nat_config.yaml.erb', {
            edge_gateway_name: @edge_name,
            org_vdc_network_id: @int_net_id,
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

        #it "and then NatService diff should highlight a difference" do
        #  diff_output = EdgeGatewayServices.new.diff(@initial_nat_config_file)
        #  expect(diff_output[:NatService].size).to eq(2)
        #end

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
      end

      after(:all) do
        reset_edge_gateway unless ENV['VCLOUD_NO_RESET_VSE_AFTER']
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
