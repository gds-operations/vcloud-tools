module Vcloud
  class Vapp < Entity

    attr_reader :vcloud_attributes

    def initialize(vcloud_attributes = {})
      @vcloud_attributes = vcloud_attributes
    end

    module STATUS
      RUNNING = 4
    end

    def name
      @vcloud_attributes[:name]
    end

    def vdc_id
      link = @vcloud_attributes[:Link].detect { |l| l[:rel] == Vcloud::RELATION::PARENT && l[:type] == Vcloud::ContentTypes::VDC }
      link ? link[:href].split('/').last : raise('a vapp without parent vdc found')
    end

    def vms
      @vcloud_attributes[:Children][:Vm]
    end

    def networks
      @vcloud_attributes[:'ovf:NetworkSection'][:'ovf:Network']
    end

    def provision(config)
      fog_interface = Vcloud::FogServiceInterface.new
      name, vdc_name = config[:name], config[:vdc_name]
      begin
        if @vcloud_attributes = fog_interface.get_vapp_by_name_and_vdc_name(name, vdc_name)
          Vcloud.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
        else
          template = Vcloud::VappTemplate.get(config[:catalog], config[:catalog_item])
          template_id = template.id

          network_names = config[:vm][:network_connections].collect { |h| h[:name] }
          networks = fog_interface.find_networks(network_names, vdc_name)

          Vcloud.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
          @vcloud_attributes = fog_interface.post_instantiate_vapp_template(
            fog_interface.vdc(vdc_name),
            template_id,
            name,
            InstantiationParams: build_network_config(networks)
          )
          vm = Vcloud::Vm.new(vms.first, self)
          vm.customize(config[:vm])
          @vcloud_attributes = fog_interface.get_vapp(id)
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

    def id_prefix
      'vapp'
    end
  end
end
