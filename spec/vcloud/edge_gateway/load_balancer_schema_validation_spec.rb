require 'spec_helper'

module Vcloud
  describe "load balancer service schema validation" do

    context "validate pool entry" do

      valid_tests = [
        {
          name: 'should validate ok if only mandatory fields are provided',
          input: {
            name: 'pool entry 1',
            members: [
              { ip_address: "192.2.0.40" },
              { ip_address: "192.2.0.41" },
            ]
          }
        },
        {
          name: 'should validate a complete pool specification',
          input: {
            name: 'pool entry 1',
            description: 'description of pool entry 1',
            service: {
              http: {
                enabled: true,
                port: 8080,
                algorithm: 'ROUND_ROBIN',
                health_check: {
                  port: 80,
                  protocol: 'HTTP',
                  health_threshold: 4,
                  unhealth_threshold: 10,
                  interval: 10,
                  timeout: 5,
                },
              },
            },
            members: [
              { ip_address: "192.2.0.40",
                weight: 2,
                service_port: {
                  http: {
                    port: 8080,
                    health_check_port: 8080,
                  }
                }
              },
            ]
          }
        },
      ]

      valid_tests.each do |test|
        it "#{test[:name]}" do
          validator = ConfigValidator.validate(:base, test[:input],
              Vcloud::Schema::LOAD_BALANCER_POOL_ENTRY)
          expect(validator.errors).to eq([])
          expect(validator.valid?).to be_true
        end
      end

    end

    context "validate virtual_server entry" do

      valid_tests = [
        {
          name: 'should validate ok if only mandatory fields are provided',
          input: {
            name: 'virtual_server entry 1',
            ip_address: "192.2.0.40",
            network: "TestNetwork",
            pool: "TestPool",
          }
        },
        {
          name: 'should validate a complete virtual_server specification',
          input: {
            name: 'virtual_server entry 1',
            ip_address: "192.2.0.40",
            network: "TestNetwork",
            pool: "TestPool",
            logging: true,
            service_profiles: {
              http: { enabled: true, port: 8080 },
              https: { enabled: false, port: 8443 },
              tcp: { enabled: false },
            },
          }
        },
      ]

      valid_tests.each do |test|
        it "#{test[:name]}" do
          validator = ConfigValidator.validate(:base, test[:input],
              Vcloud::Schema::LOAD_BALANCER_VIRTUAL_SERVER_ENTRY)
          expect(validator.errors).to eq([])
          expect(validator.valid?).to be_true
        end
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
        expect(validator.errors).to eq([])
        expect(validator.valid?).to be_true
      end

      it "should fail to validate if no pools are specified" do
        input = {
          virtual_servers: []
        }
        validator = ConfigValidator.validate(:base, input, Vcloud::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.errors).to eq(["base: missing 'pools' parameter"])
        expect(validator.valid?).to be_false
      end

      it "should fail to validate if virtual_servers section is missing" do
        input = {
          pools: []
        }
        validator = ConfigValidator.validate(:base, input, Vcloud::Schema::LOAD_BALANCER_SERVICE)
        expect(validator.errors).to eq(["base: missing 'virtual_servers' parameter"])
        expect(validator.valid?).to be_false
      end

    end

  end
end
