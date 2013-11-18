module Vcloud
  class Vapp

    attr_accessor :attributes

    module STATUS
      RUNNING = 4
    end

    def initialize(vcloud, attributes)
      @fog_interface = Vcloud::FogInterface.new
      self.attributes = attributes
    end

    def id
     return nil unless attributes && attributes[:href]
     attributes[:href].split('/').last
    end

    def name
      attributes[:name]
    end

    def vdc_id
      link = attributes[:Link].detect { |l| l[:rel] == Vcloud::RELATION::PARENT && l[:type] == Vcloud::ContentTypes::VDC }
      link ? link[:href].split('/').last : raise('a vapp without parent vdc found')
    end

    def provision(config)
      name = config[:name]
      vdc_name = config[:vdc_name]

      begin

        template = Vcloud::Template.new(@fog_interface, config)
        template_id = template.id

        network_names = config[:vm][:network_connections].collect { |h| h[:name] }
        networks = @fog_interface.find_networks(network_names, vdc_name)

        if id
          vapp = @fog_interface.get_vapp(id)
          Vcloud.logger.info("Found existing vApp #{vapp[:name]} in vDC '#{vdc_name}'. Skipping.")
        else
          Vcloud.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
          vapp = @fog_interface.post_instantiate_vapp_template(
            @fog_interface.vdc(vdc_name),
            template_id,
            name,
            InstantiationParams: build_network_config(networks)
          )
          @id = vapp[:href].split('/').last
          vm = Vcloud::Vm.new(@fog_interface, vapp[:Children][:Vm].first, self)
          vm.customize(config[:vm])
          vapp = @fog_interface.get_vapp(@id)
        end

      rescue RuntimeError => e
        Vcloud.logger.error("Could not provision vApp: #{e.message}")
      end
      vapp
    end

    def power_on
      raise "Cannot power on a missing vApp." unless id
      return true if running?
      @fog_interface.power_on_vapp(id)
      running?
    end

    def running?
      raise "Cannot call running? on a missing vApp." unless id
      vapp = @fog_interface.get_vapp(id)
      vapp[:status].to_i == STATUS::RUNNING ? true : false
    end

  private
    def build_network_config(networks)
      instantiation = {NetworkConfigSection: {NetworkConfig: []}}
      networks.compact.each do |network|
        instantiation[:NetworkConfigSection][:NetworkConfig] << {
            networkName: network[:name],
            Configuration: {
                ParentNetwork: {href: network[:href]},
                FenceMode: 'bridged',
            }
        }
      end
      instantiation
    end
  end
end
