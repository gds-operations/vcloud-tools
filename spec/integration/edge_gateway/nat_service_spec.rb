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

    context "Test NatService specifics of EdgeGatewayServices" do

      before(:all) do
        reset_edge_gateway
        @initial_nat_config_file = generate_input_config_file(
          'nat_config.yaml.erb', {
              edge_gateway_name: @edge_name,
              network_id: @ext_net_id,
              original_ip: @ext_net_ip,
            }
          )
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
      end

      context "Check update is functional" do

        it "should configure NatService" do
          expect(EdgeGatewayServices.new.update(@initial_nat_config_file)).to be_true
        end

        #it "and then should not configure the NAT service if updated again with the same configuration (idempotency)" do
        #  expect(Vcloud.logger).to receive(:info).with('EdgeGatewayServices.update: Configuration is already up to date. Skipping.')
        #  EdgeGatewayServices.new.update(@initial_nat_config_file)
        #end

        #it "and so NatService diff should return empty if both configs match" do
        #  diff_output = EdgeGatewayServices.new.diff(@initial_nat_config_file)
        #  expect(diff_output[:NatService]).to eq([])
        #end

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
        remove_temp_config_files
      end

      def remove_temp_config_files
        FileUtils.rm(@files_to_delete)
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
        edge_gateway.update_configuration({
          NatService: {:IsEnabled => "true", :NatRule => []},
        })
      end

      def generate_input_config_file(data_file, erb_input)
        config_erb = File.expand_path("data/#{data_file}", File.dirname(__FILE__))
        ErbHelper.convert_erb_template_to_yaml(erb_input, config_erb)
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
end
