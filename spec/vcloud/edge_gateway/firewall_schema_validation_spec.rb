require 'spec_helper'

module Vcloud
  describe 'firewall_service_schema_validations' do
    context 'source and destination ips' do
      it 'should error if source_ip/destination_ip are invalid IPs' do
        config = {
          firewall_rules: [
            {
              id: '999',
              description: "A rule",
              destination_port_range: "22",
              destination_ip: "10.10",
              source_ip: "192.0",
            }
          ]

        }
        validator = ConfigValidator.validate(:base, config, Schema::FIREWALL_SERVICE)
        expect(validator.valid?).to be_false
        expect(validator.errors).to eq([
                                         "source_ip: 192.0 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'.",
                                         "destination_ip: 10.10 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."
                                       ])
      end

      it 'should validate OK if source_ip/destination_ip are valid IPs' do
        config = {
          firewall_rules: [
            {
              id: '999',
              description: "A rule",
              destination_port_range: "22",
              destination_ip: "10.10.10.20",
              source_ip: "192.0.2.2",
            }
          ]

        }
        validator = ConfigValidator.validate(:base, config, Schema::FIREWALL_SERVICE)
        expect(validator.valid?).to be_true
      end
    end
  end
end
