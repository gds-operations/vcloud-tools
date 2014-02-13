require 'vcloud'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      class LoadBalancerService

        def initialize edge_gateway
          @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(edge_gateway)
        end

        def generate_fog_config(load_balancer_input_config)
          return nil if load_balancer_input_config.nil?
          vcloud_load_balancer_section = {}
          vcloud_load_balancer_section[:IsEnabled] = load_balancer_input_config.key?(:enabled) ?
              load_balancer_input_config[:enabled].to_s : 'true'
          vcloud_pools = []
          vcloud_virtual_servers = []
          if pools = load_balancer_input_config[:pools]
            pools.each do |pool_input_entry|
              vcloud_pools << generate_pool_entry(pool_input_entry)
            end
          end
          if virtual_servers = load_balancer_input_config[:virtual_servers]
            virtual_servers.each do |virtual_server_input_entry|
              vcloud_virtual_servers << generate_virtual_server_entry(virtual_server_input_entry)
            end
          end
          vcloud_load_balancer_section[:Pool] = vcloud_pools
          vcloud_load_balancer_section[:VirtualServer] = vcloud_virtual_servers
          vcloud_load_balancer_section
        end

        private

        def generate_virtual_server_entry(input_virtual_server)
          vcloud_virtual_server = {}
          vcloud_virtual_server[:IsEnabled]   = input_virtual_server.key(:enabled) ? input_virtual_server[:enabled] : 'true'
          vcloud_virtual_server[:Name]        = input_virtual_server[:name]
          vcloud_virtual_server[:Description] = input_virtual_server[:description] || ''
          vcloud_virtual_server[:Interface]   = generate_virtual_server_interface_section(input_virtual_server[:network])
          vcloud_virtual_server[:IpAddress]   = input_virtual_server[:ip_address]
          vcloud_virtual_server[:ServiceProfile] = generate_virtual_server_service_profile_section(input_virtual_server[:service_profiles])
          vcloud_virtual_server[:Logging]     = input_virtual_server.key(:logging) ? input_virtual_server[:logging] : 'false'
          vcloud_virtual_server[:Pool]        = input_virtual_server[:pool]
          vcloud_virtual_server
        end

        def generate_virtual_server_interface_section(network_id)
          vcloud_virtual_server_interface = {}
          vcloud_virtual_server_interface[:type] = 'application/vnd.vmware.vcloud.orgVdcNetwork+xml'
          vcloud_virtual_server_interface[:name] = look_up_network_name(network_id)
          vcloud_virtual_server_interface[:href] = look_up_network_href(network_id)
          vcloud_virtual_server_interface
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

        def generate_virtual_server_service_profile_section(input_service_profile)
          input_service_profile = {} if input_service_profile.nil?
          vcloud_service_profiles = []
          protocols = [ :http, :https, :tcp ]
          protocols.each do |protocol|
            vcloud_service_profiles << generate_virtual_server_service_profile_protocol_section(protocol, input_service_profile[protocol])
          end
          vcloud_service_profiles
        end

        def generate_virtual_server_service_profile_protocol_section(protocol, input_protocol_section)
          vcloud_protocol_section = {
            IsEnabled: 'false',
            Protocol: protocol.to_s.upcase,
            Port:     default_port(protocol),
            Persistence: generate_virtual_server_persistence_section(protocol, nil)
          }
          if input_protocol_section
            vcloud_protocol_section[:IsEnabled] = input_protocol_section.key?(:enabled) ? input_protocol_section[:enabled].to_s : 'true'
            vcloud_protocol_section[:Port] = input_protocol_section.key?(:port) ? input_protocol_section[:port].to_s : default_port(protocol)
            vcloud_protocol_section[:Persistence] = generate_virtual_server_persistence_section(protocol, input_protocol_section[:persistence])
          end
          vcloud_protocol_section
        end

        def default_port(protocol)
          default_port_for = { http: '80', https: '443', tcp: '' }
          default_port_for[protocol]
        end

        def generate_virtual_server_persistence_section(protocol, input_persistence_section)
          input_persistence_section = {} if input_persistence_section.nil?
          vcloud_persistence_section = { Method: '' }
          if input_persistence_section.key?(:method)
            vcloud_persistence_section[:Method] = input_persistence_section[:method] if input_persistence_section.key?(:method)
            if input_persistence_section[:method] == 'COOKIE'
              vcloud_persistence_section[:CookieName] = input_persistence_section[:cookie_name]
              vcloud_persistence_section[:CookieMode] = input_persistence_section[:cookie_mode]
            end
          end
          vcloud_persistence_section
        end

        def generate_pool_entry(input_pool_entry)
          sp_modes = [ :http, :https, :tcp ]
          vcloud_pool_entry = {}
          vcloud_pool_entry[:Name] = input_pool_entry[:name]
          vcloud_pool_entry[:Description] = input_pool_entry[:description] if input_pool_entry.key?(:description)
          vcloud_pool_entry[:ServicePort] = sp_modes.map do |mode|
            generate_pool_service_port(mode,
              input_pool_entry.key?(:service) ? input_pool_entry[:service][mode] : nil)
          end
          if input_pool_entry.key?(:members)
            vcloud_pool_entry[:Member] = []
            input_pool_entry[:members].each do |member|
              vcloud_pool_entry[:Member] << generate_pool_member_entry(member)
            end
          end
          vcloud_pool_entry
        end

        def generate_pool_member_entry(input_pool_member)
          {
            IpAddress: input_pool_member[:ip_address],
            Weight:    input_pool_member.key?(:weight) ? input_pool_member[:weight].to_s : '1',
            ServicePort: [
              { Protocol: 'HTTP',  Port: '', HealthCheckPort: '' },
              { Protocol: 'HTTPS', Port: '', HealthCheckPort: '' },
              { Protocol: 'TCP',   Port: '', HealthCheckPort: '' },
            ]
          }
        end

        def generate_pool_service_port(mode, input_pool_service_port)

          vcloud_pool_service_port = {
            IsEnabled: 'false',
            Protocol: mode.to_s.upcase,
            Algorithm: 'ROUND_ROBIN',
            Port:     default_port(mode),
            HealthCheckPort: '',
            HealthCheck: generate_pool_healthcheck(mode)
          }

          if input_pool_service_port
            vcloud_pool_service_port[:IsEnabled] = input_pool_service_port.key?(:enabled) ? input_pool_service_port[:enabled].to_s : 'true'
            vcloud_pool_service_port[:Algorithm] = input_pool_service_port[:algorithm] if input_pool_service_port.key?(:algorithm)
            vcloud_pool_service_port[:Port]      = input_pool_service_port.key?(:port) ? input_pool_service_port[:port].to_s : default_port(mode)
            if health_check = input_pool_service_port[:health_check]
              vcloud_pool_service_port[:HealthCheckPort] = health_check.key?(:port) ? health_check[:port].to_s : ''
              vcloud_pool_service_port[:HealthCheck] = generate_pool_healthcheck(mode, input_pool_service_port[:health_check])
            end
          end
          vcloud_pool_service_port
        end

        def generate_pool_healthcheck(protocol, input_pool_healthcheck_entry = nil)
          default_mode = ( protocol == :https ) ? 'SSL' : protocol.to_s.upcase
          vcloud_pool_healthcheck_entry = {
            Mode: default_mode,
          }
          vcloud_pool_healthcheck_entry[:Uri] = '' if protocol == :http
          vcloud_pool_healthcheck_entry[:Uri] = '' if ( protocol == :https ) && input_pool_healthcheck_entry && ( input_pool_healthcheck_entry[:protocol] == 'TCP' )
          vcloud_pool_healthcheck_entry[:HealthThreshold] = '2'
          vcloud_pool_healthcheck_entry[:UnhealthThreshold] = '3'
          vcloud_pool_healthcheck_entry[:Interval] = '5'
          vcloud_pool_healthcheck_entry[:Timeout] = '15'

          if input_pool_healthcheck_entry
            vcloud_pool_healthcheck_entry[:Mode] = input_pool_healthcheck_entry[:protocol] if input_pool_healthcheck_entry.key?(:protocol)
            vcloud_pool_healthcheck_entry[:Uri]  = input_pool_healthcheck_entry[:uri] if input_pool_healthcheck_entry.key?(:uri) and protocol == :http
            vcloud_pool_healthcheck_entry[:HealthThreshold] = input_pool_healthcheck_entry[:health_threshold] if
                input_pool_healthcheck_entry.key?(:health_threshold)
            vcloud_pool_healthcheck_entry[:UnhealthThreshold] = input_pool_healthcheck_entry[:unhealth_threshold] if
                input_pool_healthcheck_entry.key?(:unhealth_threshold)
            vcloud_pool_healthcheck_entry[:Interval] = input_pool_healthcheck_entry[:interval] if input_pool_healthcheck_entry.key?(:interval)
            vcloud_pool_healthcheck_entry[:Timeout] = input_pool_healthcheck_entry[:timeout] if input_pool_healthcheck_entry.key?(:timeout)
          end
          vcloud_pool_healthcheck_entry
        end

      end
    end
  end

end
