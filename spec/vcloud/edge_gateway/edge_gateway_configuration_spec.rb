require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe EdgeGatewayConfiguration do

      context "whether update is required" do

        it "returns true" do
          local_config = 'test'
          remote_config = 'test'
          proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(local_config)
          expect(proposed_config.update_required?(remote_config)).to be_true
        end
      end

    end
  end
end
