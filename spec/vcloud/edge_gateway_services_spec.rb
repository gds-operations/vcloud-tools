require 'spec_helper'

module Vcloud

  describe EdgeGatewayServices do

    before(:each) do
      edge_gateway_services = EdgeGatewayServices.edge_gateway_services
      @mock_no_diff_output = {}
      @parsed_config = {
        gateway: 'TestGateway',
      }
      edge_gateway_services.each do |service|
        @mock_no_diff_output[service] = []
        @parsed_config[service] = {}
      end

      @edge_gw_obj = double(
        :edge_gateway,
        vcloud_attributes: {
          Configuration: {
            EdgeGatewayServiceConfiguration: {
              NatService: {},
              FirewallService: {},
              LoadBalancerService: {},
            }
          }
        }
      )
    end

    context "Object public interface" do
      subject { EdgeGatewayServices.new() }
      it { should respond_to(:diff) }
      it { should respond_to(:update) }
    end

    context "Class public interface" do
      subject { EdgeGatewayServices }
      it { should respond_to(:edge_gateway_services) }
    end

    context "#update" do

      before(:each) do
        @obj = EdgeGatewayServices.new
      end

#      it "should not attempt to update config if remote config is same as the config we want to apply" do
#        expect(@obj).to receive(:translate_yaml_input).and_return(@parsed_config)
#        expect(Core::EdgeGateway).to receive(:get_by_name).and_return(@edge_gw_obj)
#        expect(@obj).to receive(:diff).and_return(@mock_no_diff_output)
#        expect(Vcloud.logger).to receive(:info).with('EdgeGatewayServices.update: Configuration is already up to date. Skipping.')
#        @obj.update("config_file")
#      end
#
#      it "should update the edgeGateway configuration only for services that are different" do
#        expect(Core::EdgeGateway).to receive(:get_by_name).and_return(@edge_gw_obj)
#        expect(@obj).to receive(:translate_yaml_input).and_return(@parsed_config)
#        expect(@obj).to receive(:diff).and_return({
#          FirewallService: [['+', "an addition"]],
#          NatService: [],
#        })
#        expect(@edge_gw_obj).to receive(:update_configuration).with({
#          gateway: 'TestGateway',
#          FirewallService: {},
#        })
#        @obj.update("config_file")
#      end
#
    end

  end

end
