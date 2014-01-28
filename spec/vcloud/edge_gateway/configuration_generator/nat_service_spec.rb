require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe NatService do
        context "nat service config generation" do

          test_cases = [
            {
              title: 'enabled nat service with single disabled rule',
              input: {
                enabled: 'true',
                nat_rules: [
                  {
                    enabled: 'false',
                    id: '999',
                    rule_type: 'DNAT',
                    description: "a dnat rule",
                    network: "ane012345",
                    original_ip: "192.0.2.2",
                    original_port: '22',
                    translated_port: '22',
                    translated_ip: "10.10.20.20",
                    protocol: 'tcp',
                  }
                ]
              },
              output: {
                :IsEnabled => 'true',
                :NatRule => [
                  {
                    :Description => 'a dnat rule',
                    :RuleType => 'DNAT',
                    :IsEnabled => 'false',
                    :Id => '999',
                    :GatewayNatRule => {
                      :Interface =>
                        {
                          :name => 'ane012345',
                          :href => 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                        },
                      :Protocol => 'tcp',
                      :OriginalIp => "192.0.2.2",
                      :OriginalPort => '22',
                      :TranslatedIp => "10.10.20.20",
                      :TranslatedPort => '22'
                    }
                  }
                ]
              }
            },
            {
              title: 'auto generate rule id if not provided',
              input: {
                enabled: 'true',
                nat_rules: [
                  {
                    enabled: 'false',
                    rule_type: 'DNAT',
                    description: "a dnat rule",
                    network: "ane012345",
                    original_ip: "192.0.2.2",
                    original_port: '22',
                    translated_port: '22',
                    translated_ip: "10.10.20.20",
                    protocol: 'tcp',
                  }
                ]
              },
              output: {
                :IsEnabled => 'true',
                :NatRule => [
                  {
                    :Description => 'a dnat rule',
                    :RuleType => 'DNAT',
                    :IsEnabled => 'false',
                    :Id => '65537',
                    :GatewayNatRule => {
                      :Interface =>
                        {
                          :name => 'ane012345',
                          :href => 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                        },
                      :Protocol => 'tcp',
                      :OriginalIp => "192.0.2.2",
                      :OriginalPort => '22',
                      :TranslatedIp => "10.10.20.20",
                      :TranslatedPort => '22'
                    }
                  }
                ]
              }
            },
            {
              title: 'should use default values for optional fields if they are missing',
              input: {
                nat_rules: [
                  {
                    rule_type: 'DNAT',
                    network: "ane012345",
                    original_ip: "192.0.2.2",
                    original_port: '22',
                    translated_port: '22',
                    translated_ip: "10.10.20.20",
                  }
                ]
              },
              output: {
                :IsEnabled => 'true',
                :NatRule => [
                  {
                    :Description => '',
                    :RuleType => 'DNAT',
                    :IsEnabled => 'true',
                    :Id => '65537',
                    :GatewayNatRule => {
                      :Interface =>
                        {
                          :name => 'ane012345',
                          :href => 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                        },
                      :Protocol => 'tcp',
                      :OriginalIp => "192.0.2.2",
                      :OriginalPort => '22',
                      :TranslatedIp => "10.10.20.20",
                      :TranslatedPort => '22'
                    }
                  }
                ]
              }
            }
          ]

          test_cases.each do |test_case|
            it "#{test_case[:title]}" do
              edge_gateway = double(:edge_gateway,
                                    :get_gateway_interface_by_id =>
                                      {
                                        Network:
                                          {
                                            :name => 'ane012345',
                                            :href => 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                                          }
                                      }
              )
              expect(Vcloud::Core::EdgeGateway).to receive(:get_by_name).with('1111111-7b54-43dd-9eb1-631dd337e5a7')
                                                   .and_return(edge_gateway)
              generated_config = NatService.new('1111111-7b54-43dd-9eb1-631dd337e5a7', test_case[:input]).generate_fog_config
              expect(generated_config).to eq(test_case[:output])
            end

          end

        end
      end
    end
  end
end
