module Vcloud
  class Vapp

    attr_reader :vdc, :name

    def initialize(vcloud, config = {})
      @fog_interface = vcloud
      @name = config[:name]
      @vdc_name = config[:vdc_name]
    end

    def id
      return nil unless @vdc_name
      return nil unless @name
      return @id unless @id.nil?
      @vdc = @fog_interface.vdc_object_by_name @vdc_name
      model_vapp = @fog_interface.get_vapp_by_vdc_and_name(@vdc, @name)
      @id = model_vapp ? model_vapp.id : nil
    end

    def provision(config)
      @name = config[:name]
      @vdc_name = config[:vdc_name]

      begin

        template = Vcloud::Template.new(@fog_interface, config)
        template_id = template.id

        network_names = config[:vm][:network_connections].collect { |h| h[:name] }
        networks = @fog_interface.find_networks(network_names, @vdc_name)

        if id
          vapp = @fog_interface.get_vapp(id)
          Vcloud.logger.info("Found existing vApp #{vapp[:name]} in vDC '#{vdc.name}'. Skipping.")
        else
          Vcloud.logger.info("Instantiating new vApp #{@name} in vDC '#{vdc.name}'")
          vapp = @fog_interface.post_instantiate_vapp_template(
            @fog_interface.vdc(@vdc_name),
            template_id,
            @name,
            InstantiationParams: build_network_config(networks)
          )
          @id = vapp[:href].split('/').last
          vm = Vm.new(@fog_interface, vapp[:Children][:Vm].first, self)
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
      vapp[:status].to_i == 4 ? true : false
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
