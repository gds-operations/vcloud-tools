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

    context "#configure_edge_gateway_services" do

      before(:all) do
        reset_edge_gateway
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
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

  end
end
