require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe NatService do

        before(:each) do
          @edge_id = '1111111-7b54-43dd-9eb1-631dd337e5a7'
          edge_gateway = double(
            :edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                name: 'ane012345',
                href: 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
              }
            }
          )
          expect(Vcloud::Core::EdgeGateway).to receive(:get_by_name).with(@edge_id)
                                               .and_return(edge_gateway)
        end

        context "SNAT rule defaults" do

          before(:each) do
            input = { nat_rules: [{
              rule_type: 'SNAT',
              network: "ane012345",
              original_ip: "192.0.2.2",
              translated_ip: "10.10.20.20",
            }]} # minimum NAT configuration with a rule
            output = NatService.new(@edge_id, input).generate_fog_config
            @rule = output[:NatRule].first
          end

          it 'should default to the rule being enabled' do
            expect(@rule[:IsEnabled]).to eq('true')
          end

          it 'should have a RuleType of SNAT' do
            expect(@rule[:RuleType]).to eq('SNAT')
          end

          it 'should not include a Protocol' do
            expect(@rule[:GatewayNatRule].key?(:Protocol)).to be_false
          end

          it 'should completely match our expected default rule' do
            expect(@rule).to eq({
              :Id=>"65537",
              :IsEnabled=>"true",
              :RuleType=>"SNAT",
              :GatewayNatRule=>{
                :Interface=>{
                  :name=>"ane012345",
                  :href=>"https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7"
                },
              :OriginalIp=>"192.0.2.2",
              :TranslatedIp=>"10.10.20.20"}
            })
          end

        end

        context "DNAT rule defaults" do

          before(:each) do
            input = { nat_rules: [{
              rule_type: 'DNAT',
              network: "ane012345",
              original_ip: "192.0.2.2",
              original_port: '22',
              translated_port: '22',
              translated_ip: "10.10.20.20",
              protocol: 'tcp',
            }]} # minimum NAT configuration with a rule
            output = NatService.new(@edge_id, input).generate_fog_config
            @rule = output[:NatRule].first
          end

          it 'should default to rule being enabled' do
            expect(@rule[:IsEnabled]).to eq('true')
          end

          it 'should have a RuleType of DNAT' do
            expect(@rule[:RuleType]).to eq('DNAT')
          end

          it 'should include a default Protocol of tcp' do
            expect(@rule[:GatewayNatRule][:Protocol]).to eq('tcp')
          end

          it 'should completely match our expected default rule' do
            expect(@rule).to eq({
              :Id=>"65537",
              :IsEnabled=>"true",
              :RuleType=>"DNAT",
              :GatewayNatRule=>{
                :Interface=>{
                  :name=>"ane012345",
                  :href=>"https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7"
                },
                :OriginalIp=>"192.0.2.2",
                :TranslatedIp=>"10.10.20.20",
                :OriginalPort=>"22",
                :TranslatedPort=>"22",
                :Protocol=>"tcp"
              }
            })
          end

        end

        context "nat service config generation" do

          test_cases = [
            {
              title: 'should generate config for enabled nat service with single disabled DNAT rule',
              input: {
                enabled: 'true',
                nat_rules: [
                  {
                    enabled: 'false',
                    id: '999',
                    rule_type: 'DNAT',
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
              title: 'should generate config for enabled nat service with single disabled SNAT rule',
              input: {
                enabled: 'true',
                nat_rules: [
                  {
                    enabled: 'false',
                    rule_type: 'SNAT',
                    network: "ane012345",
                    original_ip: "192.0.2.2",
                    translated_ip: "10.10.20.20",
                  }
                ]
              },
              output: {
                :IsEnabled => 'true',
                :NatRule => [
                  {
                    :RuleType => 'SNAT',
                    :IsEnabled => 'false',
                    :Id => '65537',
                    :GatewayNatRule => {
                      :Interface =>
                        {
                          :name => 'ane012345',
                          :href => 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                        },
                      :OriginalIp => "192.0.2.2",
                      :TranslatedIp => "10.10.20.20",
                    }
                  }
                ]
              }
            },

            {
              title: 'should auto generate rule id if not provided',
              input: {
                enabled: 'true',
                nat_rules: [
                  {
                    enabled: 'false',
                    rule_type: 'DNAT',
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
              generated_config = NatService.new(@edge_id, test_case[:input]).generate_fog_config
              expect(generated_config).to eq(test_case[:output])
            end
          end

        end
      end
    end
  end
end
