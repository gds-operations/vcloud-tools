require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe FirewallConfigurationGenerator do
      context "firewall config generation" do

        test_cases = [
          {
            title: 'disabled firewall with a disabled rule',
            input: {
              enabled: false,
              policy: 'allow',
              log_default_action: true,
              firewall_rules: [
                {
                  enabled: false,
                  id: '999',
                  match_on_translate: true,
                  description: "A rule",
                  policy: "allow",
                  protocols: "tcp+udp",
                  destination_port_range: "22",
                  destination_ip: "10.10.20.20",
                  source_port_range: "Any",
                  source_ip: "192.0.2.2",
                  enable_logging: true,
                }
              ]
            },
            output: {
              IsEnabled: false,
              DefaultAction: "allow",
              LogDefaultAction: true,
              FirewallRule: [
                {
                  Id: '999',
                  IsEnabled: false,
                  Description: "A rule",
                  MatchOnTranslate: true,
                  Policy: "allow",
                  Protocols: {Tcp: true, Udp: true},
                  DestinationPortRange: "22",
                  DestinationIp: "10.10.20.20",
                  SourcePortRange: "Any",
                  SourceIp: "192.0.2.2",
                  EnableLogging: true,
                }
              ]
            }
          },
          {
            title: 'should use default values for missing fields',
            input: {
              firewall_rules: [
                {
                  id: '999',
                  description: "A rule",
                  destination_port_range: "22",
                  destination_ip: "10.10.20.20",
                  source_ip: "192.0.2.2",
                }
              ]

            },
            output: {
              IsEnabled: true,
              DefaultAction: "drop",
              LogDefaultAction: false,
              FirewallRule: [
                {
                  Id: '999',
                  IsEnabled: true,
                  Description: "A rule",
                  MatchOnTranslate: false,
                  Policy: "allow",
                  Protocols: {Tcp: true},
                  DestinationPortRange: "22",
                  DestinationIp: "10.10.20.20",
                  SourcePortRange: "Any",
                  SourceIp: "192.0.2.2",
                  EnableLogging: false,
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
              IsEnabled: true,
              DefaultAction: "drop",
              LogDefaultAction: false,
              FirewallRule: [
                {
                  Id: 1,
                  IsEnabled: true,
                  Description: "rule 1",
                  MatchOnTranslate: false,
                  Policy: "allow",
                  Protocols: {Tcp: true},
                  DestinationPortRange: "22",
                  DestinationIp: "10.10.20.20",
                  SourcePortRange: "Any",
                  SourceIp: "192.0.2.2",
                  EnableLogging: false,
                },
                {
                  Id: 2,
                  IsEnabled: true,
                  Description: "rule 2",
                  MatchOnTranslate: false,
                  Policy: "allow",
                  Protocols: {Tcp: true},
                  DestinationPortRange: "22",
                  DestinationIp: "10.10.20.20",
                  SourcePortRange: "Any",
                  SourceIp: "192.0.2.2",
                  EnableLogging: false,
                }

              ]
            }
          }
        ]

        test_cases.each do |test_case|
          it "#{test_case[:title]}" do
            generated_config = FirewallConfigurationGenerator.new.firewall_config test_case[:input]
            expect(generated_config).to eq(test_case[:output])
          end

        end

      end
    end
  end
end
