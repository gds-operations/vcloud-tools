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

    context "Test EdgeGatewayServices with multiple services" do

      before(:all) do
        reset_edge_gateway
        @initial_config_file = generate_input_config_file('nat_and_firewall_config.yaml.erb', edge_gateway_erb_input)
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
      end

      context "Check update is functional" do

        before(:all) do
          local_config = ConfigLoader.new.load_config(@initial_config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
        end

        it "should be starting our tests from an empty EdgeGateway" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          expect(remote_vcloud_config[:FirewallService][:FirewallRule].empty?).to be_true
          expect(remote_vcloud_config[:NatService][:NatRule].empty?).to be_true
        end

        it "should only need to make one call to Core::EdgeGateway.update_configuration" do
          expect_any_instance_of(Core::EdgeGateway).to receive(:update_configuration).exactly(1).times.and_call_original
          EdgeGatewayServices.new.update(@initial_config_file)
        end

        it "should now have nat and firewall rules configured" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          expect(remote_vcloud_config[:FirewallService][:FirewallRule].empty?).to be_false
          expect(remote_vcloud_config[:NatService][:NatRule].empty?).to be_false
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
        output_file = ErbHelper.convert_erb_template_to_yaml(erb_input, config_erb)
        @files_to_delete << output_file
        output_file
      end

      def edge_gateway_erb_input
        {
          edge_gateway_name: @edge_name,
          network_id: @ext_net_id,
          original_ip: @ext_net_ip,
        }
      end

    end

  end
end
