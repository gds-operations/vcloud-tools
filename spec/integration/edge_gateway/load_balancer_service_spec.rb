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

    context "Test LoadBalancerService specifics of EdgeGatewayServices" do

      before(:all) do
        reset_edge_gateway
        @initial_load_balancer_config_file =
          generate_input_config_file('load_balancer_config.yaml.erb', edge_gateway_erb_input)
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
      end

      context "Check update is functional" do

        before(:all) do
          local_config = ConfigLoader.new.load_config(@initial_load_balancer_config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)
          @local_vcloud_config  = EdgeGateway::ConfigurationGenerator::LoadBalancerService.new(@edge_name).generate_fog_config(local_config[:load_balancer_service])
        end

        it "should be starting our tests from an empty LoadBalancerService" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].empty?).to be_true
          expect(remote_vcloud_config[:VirtualServer].empty?).to be_true
        end

        it "should only make one EdgeGateway update task, to minimise EdgeGateway reload events" do
          start_time = DateTime.now()
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGatewayServices.new.update(@initial_load_balancer_config_file)
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should have configured at least one LoadBancer Pool entry" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].empty?).to be_false
        end

        it "should have configured at least one LoadBancer VirtualServer entry" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:VirtualServer].empty?).to be_false
        end

        it "should have configured the same number of Pools as in our configuration" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].size).
            to eq(@local_vcloud_config[:Pool].size)
        end

        it "should have configured the same number of VirtualServers as in our configuration" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:VirtualServer].size).
            to eq(@local_vcloud_config[:VirtualServer].size)
        end

        it "ConfigurationDiffer should return empty if local and remote LoadBalancer configs match" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          pp @local_vcloud_config
          pp remote_vcloud_config
          differ = EdgeGateway::ConfigurationDiffer.new(@local_vcloud_config, remote_vcloud_config)
          diff_output = differ.diff
          expect(diff_output).to eq([])
        end

        it "and then should not configure the LoadBalancerService if updated again with the same configuration (idempotency)" do
          expect(Vcloud.logger).to receive(:info).with('EdgeGatewayServices.update: Configuration is already up to date. Skipping.')
          EdgeGatewayServices.new.update(@initial_load_balancer_config_file)
        end

      end

      after(:all) do
        reset_edge_gateway unless ENV['VCLOUD_NO_RESET_VSE_AFTER']
        FileUtils.rm(@files_to_delete)
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
        edge_gateway.update_configuration({
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
          :edge_gateway_name => @edge_name,
          :edge_gateway_ext_network_id => @ext_net_id,
          :edge_gateway_ext_network_ip => @ext_net_ip,
        }
      end

      def get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(timestamp)
        vcloud_time = timestamp.strftime('%FT%T.000Z')
        q = Query.new('task',
          :filter => "name==networkConfigureEdgeGatewayServices;objectName==#{@edge_name};startDate=ge=#{vcloud_time}",
          :sortDesc => 'startDate',
        )
        q.get_all_results
      end

    end

  end
end
