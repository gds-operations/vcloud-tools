require 'vcloud'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      class LoadBalancerService

        def generate_fog_config(input_config)
          return nil if input_config.nil?
          out = {}
          out[:IsEnabled] = input_config.key?(:enabled) ?
              input_config[:enabled].to_s : 'true'
          out_pools = []
          out_vs = []
          if pools = input_config[:pools]
            pools.each do |pool|
              out_pools << generate_pool_entry(pool)
            end
          end
          if vses = input_config[:virtual_servers]
            vses.each do |vs|
              out_vs << generate_virtual_server_entry(vs)
            end
          end
          out[:Pool] = out_pools
          out[:VirtualServer] = out_vs
          out
        end

        private

        def generate_virtual_server_entry(attrs)
          out = {}
          out[:IsEnabled] = attrs.key(:enabled) ? attrs[:enabled] : 'true'
          out[:Name] = attrs[:name]
          out[:Description] = attrs[:description] || ''
          out[:Interface] = generate_vs_interface_section(attrs[:network])
          out[:IpAddress] = attrs[:ip_address]
          out[:ServiceProfile] = generate_vs_service_profile_section(attrs[:service_profiles])
          out[:Logging] = attrs.key(:logging) ? attrs[:logging] : 'false'
          out[:Pool] = attrs[:pool]
          out
        end

        def generate_vs_interface_section(network_name)
          out = {}
          out[:name] = network_name
          out[:href] = look_up_network_href(network_name)
          out[:type] = 'application/vnd.vmware.vcloud.orgVdcNetwork+xml'
          out
        end

        def look_up_network_href(name)
          'https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012'
        end

        def generate_vs_service_profile_section(attrs)
          attrs = {} if attrs.nil?
          out = []
          protocols = [ :http, :https, :tcp ]
          protocols.each do |protocol|
            out << generate_vs_service_profile_protocol_section(protocol, attrs[protocol])
          end
          out
        end

        def generate_vs_service_profile_protocol_section(protocol, attrs)
          out = {
            IsEnabled: 'false',
            Protocol: protocol.to_s.upcase,
            Port:     '',
            Persistence: generate_vs_persistence_section(protocol, nil)
          }
          if attrs
            out[:IsEnabled] = attrs.key?(:enabled) ? attrs[:enabled].to_s : 'true'
            out[:Port] = attrs.key?(:port) ? attrs[:port].to_s : default_port(protocol)
            out[:Persistence] = generate_vs_persistence_section(protocol, attrs[:persistence])
          end
          out
        end

        def default_port(protocol)
          dp = { http: '80', https: '443', tcp: '' }
          dp[protocol]
        end

        def generate_vs_persistence_section(protocol, attrs)
          attrs = {} if attrs.nil?
          { Method: '' }
        end

        def generate_pool_entry(attrs)
          sp_modes = [ :http, :https, :tcp ]
          out = {}
          out[:Name] = attrs[:name]
          out[:Description] = attrs[:description] || ''
          out[:ServicePort] = sp_modes.map do |mode|
            generate_pool_service_port(mode, attrs[:service][mode])
          end
          if attrs.key?(:members)
            out[:Member] = []
            attrs[:members].each do |member|
              out[:Member] << generate_pool_member_entry(member)
            end
          end
          out
        end

        def generate_pool_member_entry(attrs)
          {
            IpAddress: attrs[:ip_address],
            Weight:    attrs[:weight] || '1',
            ServicePort: [
              { Protocol: 'HTTP',  Port: '', HealthCheckPort: '' },
              { Protocol: 'HTTPS', Port: '', HealthCheckPort: '' },
              { Protocol: 'TCP',   Port: '', HealthCheckPort: '' },
            ]
          }
        end

        def generate_pool_service_port(mode, attrs)

          out = {
            IsEnabled: 'false',
            Protocol: mode.to_s.upcase,
            Algorithm: 'ROUND_ROBIN',
            Port:     '',
            HealthCheckPort: '',
            HealthCheck: generate_pool_healthcheck(mode)
          }

          if attrs
            out[:IsEnabled] = attrs.key?(:enabled) ? attrs[:enabled].to_s : 'true'
            out[:Algorithm] = attrs[:algorithm] if attrs.key?(:algorithm)
            out[:Port]      = attrs.key?(:port) ? attrs[:port].to_s : default_port(mode)
            if attrs.key?(:health_check)
              out[:HealthCheckPort] = attrs[:health_check].key?(:port) ?
                  attrs[:health_check][:port] : default_port[mode]
              out[:HealthCheck] = generate_pool_healthcheck(mode, attrs[:health_check])
            end
          end
          out
        end

        def generate_pool_healthcheck(protocol, attrs = nil)
          default_mode = ( protocol == :https ) ? 'SSL' : protocol.to_s.upcase
          out = {
            Mode: default_mode,
            Uri: '',
            HealthThreshold: '2',
            UnhealthThreshold: '3',
            Interval: '5',
            Timeout: '15'
          }
          if attrs
            out[:Mode] = attrs[:protocol] if attrs.key?(:protocol)
            out[:HealthThreshold] = attrs[:health_threshold] if
                attrs.key?(:health_threshold)
            out[:UnhealthThreshold] = attrs[:unhealth_threshold] if
                attrs.key?(:unhealth_threshold)
            out[:Interval] = attrs[:interval] if attrs.key?(:interval)
            out[:Timeout] = attrs[:timeout] if attrs.key?(:timeout)
          end
          out
        end

      end
    end
  end

end
