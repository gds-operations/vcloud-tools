require 'spec_helper'

module Vcloud
  describe "nat service schema validation" do
    let(:network_uuid){ SecureRandom.uuid }
    context "validate nat rule" do
      it "validate ok if only mandatory fields are provided" do
        snat_rule = {
          id: '999',
          rule_type: 'DNAT',
          network_id: network_uuid,
          original_ip: "192.0.2.2",
          translated_ip: "10.10.20.20",

        }
        validator = ConfigValidator.validate(:base, snat_rule, Vcloud::Schema::NAT_RULE)
        expect(validator.valid?).to be_true
        expect(validator.errors).to be_empty

      end

      context "mandatory field validation" do
        before(:each) do
          @snat_rule = {
            id: '999',
            rule_type: 'DNAT',
            network_id: network_uuid,
            original_ip: "192.0.2.2",
            translated_ip: "10.10.20.20",
          }
        end
        mandatory_fields = [:network_id, :original_ip, :translated_ip, :rule_type]
        mandatory_fields.each do |mandatory_field|
          it "should error since mandatory field #{mandatory_field} is missing" do
            @snat_rule.delete(mandatory_field)
            validator = ConfigValidator.validate(:base, @snat_rule, Vcloud::Schema::NAT_RULE)
            expect(validator.valid?).to be_false
            expect(validator.errors).to eq(["base: missing '#{mandatory_field}' parameter"])
          end
        end
      end

      it "should accept optional fields: original_port, translated_port and protocol as input" do
        snat_rule = {
          id: '999',
          rule_type: 'DNAT',
          network_id: network_uuid,
          original_ip: "192.0.2.2",
          original_port: "22",
          translated_ip: "10.10.20.20",
          translated_port: "22",
          protocol: 'tcp'

        }
        validator = ConfigValidator.validate(:base, snat_rule, Vcloud::Schema::NAT_RULE)
        expect(validator.valid?).to be_true
        expect(validator.errors).to be_empty
      end
    end

    context 'validate nat service config' do
      it "should validate both snat and dnat rules" do
        nat_service = {
          :enabled => true,
          :nat_rules => [
            {
              id: '999',
              enabled: true,
              rule_type: 'DNAT',
              network_id: network_uuid,
              original_ip: "192.0.2.2",
              original_port: "22",
              translated_ip: "10.10.20.20",
              translated_port: "22",
              protocol: 'tcp',
            },
            {
              id: '999',
              rule_type: 'SNAT',
              network_id: network_uuid,
              original_ip: "192.0.2.2",
              translated_ip: "10.10.20.20",
              protocol: 'tcp',
            }
          ]
        }
        validator = ConfigValidator.validate(:base, nat_service, Vcloud::Schema::NAT_SERVICE)
        expect(validator.valid?).to be_true
        expect(validator.errors).to be_empty
      end
    end
  end
end
