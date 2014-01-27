require 'spec_helper'

module Vcloud
  describe "load balancer service schema validation" do

    context "validate pool entry" do

      it "validate ok if only mandatory fields are provided" do
        input = {
          name: 'pool entry 1',
          members: [
            { ip_address: "192.2.0.40" },
            { ip_address: "192.2.0.41" },
          ]
        }
        validator = ConfigValidator.validate(:base, input, Vcloud::Schema::LOAD_BALANCER_POOL_ENTRY)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

    end

    context "validate virtual_server entry" do

      it "validate ok if only mandatory fields are provided" do
        input = {
          name: 'virtual_server entry 1',
          ip_address: "192.2.0.40",
          network: "TestNetwork",
          pool: "TestPool",
        }
        validator = ConfigValidator.validate(:base, input, Vcloud::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end
    end

    context "check complete load balancer sections" do

      it "validate ok if only mandatory fields are provided" do
        input = {
          pools: [
            {
              name: 'pool entry 1',
              members: [
                { ip_address: "192.2.0.40" },
                { ip_address: "192.2.0.41" },
              ]
            },
          ],
          virtual_servers: [
            {
              name: 'virtual_server entry 1',
              ip_address: "192.2.0.40",
              network: "TestNetwork",
              pool: "TestPool",
            },
          ],
        }
        validator = ConfigValidator.validate(:base, input, Vcloud::Schema::LOAD_BALANCER_SERVICE)
      end

    end

  end
end
