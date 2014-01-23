require 'spec_helper'

module Vcloud


  describe EdgeGatewayServices do
    it "raise exception if input yaml does not match with schema" do
      config_yaml = File.expand_path('data/incorrect_firewall_config.yaml', File.dirname(__FILE__))
      expect { EdgeGatewayServices.new.update(config_yaml) }.to raise_error('Supplied configuration does not match supplied schema')
    end

    context "#configure_edge_gateway_services" do
      before(:all) do
        reset_firewall
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
      after(:all) do
        reset_firewall
      end
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

    def reset_firewall
      edge_gateway = Core::EdgeGateway.get_by_name ENV['VCLOUD_EDGE_GATEWAY']
      edge_gateway.update_configuration({ FirewallService: { IsEnabled: false, FirewallRule: []} })
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
