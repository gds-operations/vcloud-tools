require 'spec_helper'

module Vcloud

  describe EdgeGatewayServices do

    before(:each) do
      @parsed_config = {
          gateway: 'TestGateway',
          FirewallService: {},
          NatService: {},
      }
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

    context "#update" do

      before(:each) do
        @obj = EdgeGatewayServices.new
      end

      it "should have idempotent operation (should not update config if it has not changed" do
        expect(@obj).to receive(:translate_yaml_input).and_return(@parsed_config)
        expect(Core::EdgeGateway).to receive(:get_by_name).and_return(@edge_gw_obj)
        expect(@obj).to receive(:diff).and_return([])
        expect(@edge_gw_obj).to receive(:update_configuration).at_most(0).times
        @obj.update("config_file")
      end

      it "should update the edgeGateway if the configuration is different" do
        expect(Core::EdgeGateway).to receive(:get_by_name).and_return(@edge_gw_obj)
        expect(@obj).to receive(:translate_yaml_input).and_return(@parsed_config)
        expect(@obj).to receive(:diff).and_return([['+', "an addition"]])
        expect(@edge_gw_obj).to receive(:update_configuration).with(@parsed_config)
        @obj.update("config_file")
      end

    end

  end

end
