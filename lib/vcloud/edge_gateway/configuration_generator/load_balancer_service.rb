require 'vcloud'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      class LoadBalancerService

        def initialize edge_gateway
          @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(edge_gateway)
        end

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

        def generate_vs_interface_section(network_id)
          out = {}
          out[:type] = 'application/vnd.vmware.vcloud.orgVdcNetwork+xml'
          out[:name] = look_up_network_name(network_id)
          out[:href] = look_up_network_href(network_id)
          out
        end

        def look_up_network_name(network_id)
          gateway_interface = @edge_gateway.vcloud_gateway_interface_by_id(network_id)
          raise "Could not find network #{network_id}" unless gateway_interface
          gateway_interface[:Network][:name]
        end

        def look_up_network_href(network_id)
          gateway_interface = @edge_gateway.vcloud_gateway_interface_by_id(network_id)
          raise "Could not find network #{network_id}" unless gateway_interface
          gateway_interface[:Network][:href]
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
            Port:     default_port(protocol),
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
          out = { Method: '' }
          if attrs.key?(:method)
            out[:Method] = attrs[:method] if attrs.key?(:method)
            if attrs[:method] == 'COOKIE'
              out[:CookieName] = attrs[:cookie_name]
              out[:CookieMode] = attrs[:cookie_mode]
            end
          end
          out
        end

        def generate_pool_entry(attrs)
          sp_modes = [ :http, :https, :tcp ]
          out = {}
          out[:Name] = attrs[:name]
          out[:Description] = attrs[:description] if attrs.key?(:description)
          out[:ServicePort] = sp_modes.map do |mode|
            generate_pool_service_port(mode,
              attrs.key?(:service) ? attrs[:service][mode] : nil)
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
            Weight:    attrs.key?(:weight) ? attrs[:weight].to_s : '1',
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
            Port:     default_port(mode),
            HealthCheckPort: '',
            HealthCheck: generate_pool_healthcheck(mode)
          }

          if attrs
            out[:IsEnabled] = attrs.key?(:enabled) ? attrs[:enabled].to_s : 'true'
            out[:Algorithm] = attrs[:algorithm] if attrs.key?(:algorithm)
            out[:Port]      = attrs.key?(:port) ? attrs[:port].to_s : default_port(mode)
            if health_check = attrs[:health_check]
              out[:HealthCheckPort] = health_check.key?(:port) ? health_check[:port].to_s : ''
              out[:HealthCheck] = generate_pool_healthcheck(mode, attrs[:health_check])
            end
          end
          out
        end

        def generate_pool_healthcheck(protocol, attrs = nil)
          default_mode = ( protocol == :https ) ? 'SSL' : protocol.to_s.upcase
          out = {
            Mode: default_mode,
          }
          out[:Uri] = '' if protocol == :http
          out[:Uri] = '' if ( protocol == :https ) && attrs && ( attrs[:protocol] == 'TCP' )
          out[:HealthThreshold] = '2'
          out[:UnhealthThreshold] = '3'
          out[:Interval] = '5'
          out[:Timeout] = '15'

          if attrs
            out[:Mode] = attrs[:protocol] if attrs.key?(:protocol)
            out[:Uri]  = attrs[:uri] if attrs.key?(:uri) and protocol == :http
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
