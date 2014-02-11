require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe FirewallService do

        context "top level firewall configuration defaults" do

          before(:all) do
            input = { } # minimum firewall configuration
            @output = FirewallService.new.generate_fog_config input
          end

          it 'should default to FirewallService enabled' do
            expect(@output[:IsEnabled]).to eq('true')
          end

          it 'should set the firewall action to DROP packets by default' do
            expect(@output[:DefaultAction]).to eq('drop')
          end

          it 'should set the firewall to not log by default' do
            expect(@output[:LogDefaultAction]).to eq('false')
          end

        end

        context "firewall rule defaults" do

          before(:all) do
            input = { firewall_rules: [{
              destination_ip: "192.2.0.88",
              destination_port_range: "5000-5010",
              source_ip: "Any",
            }]} # minimum firewall configuration with a rule
            output = FirewallService.new.generate_fog_config input
            @rule = output[:FirewallRule].first
          end

          it 'should default to rule being enabled' do
            expect(@rule[:IsEnabled]).to eq('true')
          end

          it 'should default to rule policy being "allow"' do
            expect(@rule[:Policy]).to eq('allow')
          end

          it 'should default to rule protocol being TCP-only' do
            expect(@rule[:Protocols]).to eq({Tcp: 'true'})
          end

          it 'should default to source port range being "Any"' do
            expect(@rule[:SourcePortRange]).to eq('Any')
          end

          it 'should default to MatchOnTranslate to be false' do
            expect(@rule[:MatchOnTranslate]).to eq('false')
          end

          it 'should have an empty default description' do
            expect(@rule[:Description]).to eq('')
          end

        end

        context "firewall config generation" do

          test_cases = [

            {
              title: 'disabled firewall with a disabled rule',
              input: {
                enabled: 'false',
                policy: 'allow',
                log_default_action: 'true',
                firewall_rules: [
                  {
                    enabled: 'false',
                    id: '999',
                    match_on_translate: 'true',
                    description: "A rule",
                    policy: "allow",
                    protocols: "tcp+udp",
                    destination_port_range: "22",
                    destination_ip: "10.10.20.20",
                    source_port_range: "Any",
                    source_ip: "192.0.2.2",
                    enable_logging: 'true',
                  }
                ]
              },
              output: {
                IsEnabled: 'false',
                DefaultAction: "allow",
                LogDefaultAction: 'true',
                FirewallRule: [
                  {
                    Id: '999',
                    IsEnabled: 'false',
                    Description: "A rule",
                    MatchOnTranslate: 'true',
                    Policy: "allow",
                    Protocols: {Tcp: 'true', Udp: 'true'},
                    Port: '22',
                    SourcePort: '-1',
                    DestinationPortRange: "22",
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourceIp: "192.0.2.2",
                    EnableLogging: 'true',
                  }
                ]
              }
            },

            {
              title: 'id should be auto generated if not provided',
              input: {
                firewall_rules: [
                  {
                    description: "rule 1",
                    destination_port_range: "22",
                    destination_ip: "10.10.20.20",
                    source_ip: "192.0.2.2",
                  },
                  {
                    description: "rule 2",
                    destination_port_range: "22",
                    destination_ip: "10.10.20.20",
                    source_ip: "192.0.2.2",
                  }
                ]
              },
              output: {
                IsEnabled: 'true',
                DefaultAction: "drop",
                LogDefaultAction: 'false',
                FirewallRule: [
                  {
                    Id: '1',
                    IsEnabled: 'true',
                    Description: "rule 1",
                    MatchOnTranslate: 'false',
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    Port: '22',
                    SourcePort: '-1',
                    DestinationPortRange: "22",
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourceIp: "192.0.2.2",
                    EnableLogging: 'false',
                  },
                  {
                    Id: '2',
                    IsEnabled: 'true',
                    Description: "rule 2",
                    MatchOnTranslate: 'false',
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    Port: '22',
                    SourcePort: '-1',
                    DestinationPortRange: "22",
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourceIp: "192.0.2.2",
                    EnableLogging: 'false',
                  }
                ]
              }


            } ,
            {
              title: 'should send port as -1 if destination/source_port_ranges are ranges',
              input: {
                firewall_rules: [
                  {
                    description: "rule 1",
                    destination_port_range: "22-23",
                    source_port_range: "1000-1004",
                    destination_ip: "10.10.20.20",
                    source_ip: "192.0.2.2",
                  }
                ]
              },
              output: {
                IsEnabled: 'true',
                DefaultAction: "drop",
                LogDefaultAction: 'false',
                FirewallRule: [
                  {
                    Id: '1',
                    IsEnabled: 'true',
                    Description: "rule 1",
                    MatchOnTranslate: 'false',
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "22-23",
                    Port: '-1',
                    SourcePort: '-1',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "1000-1004",
                    SourceIp: "192.0.2.2",
                    EnableLogging: 'false',
                  }
                ]
              }
            } ,
            {
              title: 'should send port same as destination/source_port_range if destination/source_port_range are decimals and not ranges',
              input: {
                firewall_rules: [
                  {
                    description: "rule 1",
                    destination_port_range: "22",
                    source_port_range: "1000",
                    destination_ip: "10.10.20.20",
                    source_ip: "192.0.2.2",
                  }
                ]
              },
              output: {
                IsEnabled: 'true',
                DefaultAction: "drop",
                LogDefaultAction: 'false',
                FirewallRule: [
                  {
                    Id: '1',
                    IsEnabled: 'true',
                    Description: "rule 1",
                    MatchOnTranslate: 'false',
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    Port: '22',
                    SourcePort: '1000',
                    DestinationPortRange: "22",
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "1000",
                    SourceIp: "192.0.2.2",
                    EnableLogging: 'false',
                  }
                ]
              },
              title: 'output rule order should be same as the input rule order',
              input: {
                firewall_rules: [
                  {
                    description: "rule 1",
                    destination_port_range: "8081",
                    destination_ip: "10.10.20.20",
                    source_ip: "Any",
                  },
                  {
                    description: "rule 2",
                    destination_port_range: "8082",
                    destination_ip: "10.10.20.20",
                    source_ip: "Any",
                  },
                  {
                    description: "rule 3",
                    destination_port_range: "8083",
                    destination_ip: "10.10.20.20",
                    source_ip: "Any",
                  },
                  {
                    description: "rule 4",
                    destination_port_range: "8084",
                    destination_ip: "10.10.20.20",
                    source_ip: "Any",
                  },
                  {
                    description: "rule 5",
                    destination_port_range: "8085",
                    destination_ip: "10.10.20.20",
                    source_ip: "Any",
                  },
                ],
              },
              output: {
                IsEnabled: 'true',
                DefaultAction: "drop",
                LogDefaultAction: 'false',
                FirewallRule: [
                  {
                    Id: '1',
                    IsEnabled: 'true',
                    MatchOnTranslate: 'false',
                    Description: "rule 1",
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "8081",
                    Port: '8081',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourcePort: '-1',
                    SourceIp: "Any",
                    EnableLogging: 'false',
                  },
                  {
                    Id: '2',
                    IsEnabled: 'true',
                    MatchOnTranslate: 'false',
                    Description: "rule 2",
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "8082",
                    Port: '8082',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourcePort: '-1',
                    SourceIp: "Any",
                    EnableLogging: 'false',
                  },
                  {
                    Id: '3',
                    IsEnabled: 'true',
                    MatchOnTranslate: 'false',
                    Description: "rule 3",
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "8083",
                    Port: '8083',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourcePort: '-1',
                    SourceIp: "Any",
                    EnableLogging: 'false',
                  },
                  {
                    Id: '4',
                    IsEnabled: 'true',
                    MatchOnTranslate: 'false',
                    Description: "rule 4",
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "8084",
                    Port: '8084',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourcePort: '-1',
                    SourceIp: "Any",
                    EnableLogging: 'false',
                  },
                  {
                    Id: '5',
                    IsEnabled: 'true',
                    MatchOnTranslate: 'false',
                    Description: "rule 5",
                    Policy: "allow",
                    Protocols: {Tcp: 'true'},
                    DestinationPortRange: "8085",
                    Port: '8085',
                    DestinationIp: "10.10.20.20",
                    SourcePortRange: "Any",
                    SourcePort: '-1',
                    SourceIp: "Any",
                    EnableLogging: 'false',
                  }
                ]
              }
            }
          ]

          test_cases.each do |test_case|
            it "#{test_case[:title]}" do
              generated_config = FirewallService.new.generate_fog_config test_case[:input]
              expect(generated_config).to eq(test_case[:output])
            end

          end

        end
      end
    end
  end
end
