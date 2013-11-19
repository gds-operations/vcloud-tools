module Vcloud
  class Vapp < Entity

    attr_accessor :attributes

    def initialize(attributes = {})
      self.attributes = attributes
    end

    module STATUS
      RUNNING = 4
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

    def vms
      attributes[:Children][:Vm]
    end

    def networks
      attributes[:'ovf:NetworkSection'][:'ovf:Network']
    end

    def provision(config)
      fog_interface = Vcloud::FogServiceInterface.new
      name, vdc_name = config[:name], config[:vdc_name]
      begin

        template = Vcloud::Template.new(fog_interface, config)
        template_id = template.id

        network_names = config[:vm][:network_connections].collect { |h| h[:name] }
        networks = fog_interface.find_networks(network_names, vdc_name)

        if @attributes = fog_interface.get_vapp_by_name_and_vdc_name(name, vdc_name)
          Vcloud.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
        else
          Vcloud.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
          @attributes = fog_interface.post_instantiate_vapp_template(
            fog_interface.vdc(vdc_name),
            template_id,
            name,
            InstantiationParams: build_network_config(networks)
          )
          vm = Vcloud::Vm.new(fog_interface, vms.first, self)
          vm.customize(config[:vm])
          self.attributes = fog_interface.get_vapp(id)
        end

      rescue RuntimeError => e
        Vcloud.logger.error("Could not provision vApp: #{e.message}")
      end
      self
    end


    def power_on
      raise "Cannot power on a missing vApp." unless id
      return true if running?
      Vcloud::FogServiceInterface.new.power_on_vapp(id)
      running?
    end

  private
    def running?
      raise "Cannot call running? on a missing vApp." unless id
      vapp = Vcloud::FogServiceInterface.new.get_vapp(id)
      vapp[:status].to_i == STATUS::RUNNING ? true : false
    end

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
