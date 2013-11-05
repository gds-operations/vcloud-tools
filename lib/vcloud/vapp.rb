module Vcloud
  class Vapp

    attr_reader :vdc, :id, :name

    def initialize vcloud
      @fog_interface = vcloud
    end

    def provision config, vdc_name, template
      @vdc = @fog_interface.vdc_object_by_name vdc_name
      @name = config[:name]
      network_names = config[:vm][:network_connections].collect { |h| h[:name] }
      networks = @fog_interface.find_networks(network_names, vdc_name)
      if model_vapp = @fog_interface.get_vapp_by_vdc_and_name(@vdc, @name)
        vapp = @fog_interface.get_vapp(model_vapp.id)
        Vcloud.logger.info("Found existing vApp #{vapp[:name]} in vDC '#{vdc.name}'. Skipping.")
      else
        Vcloud.logger.info("Instantiating new vApp #{@name} in vDC '#{vdc.name}'")
        vapp = @fog_interface.post_instantiate_vapp_template(
          @fog_interface.vdc(vdc_name),
          template[:href].split('/').last,
          @name,
          InstantiationParams: build_network_config(networks)
        ).body
        @id = vapp[:href].split('/').last
        vm = Vm.new(@fog_interface, vapp[:Children][:Vm].first, self)
        vm.customize(config[:vm])
        vapp = @fog_interface.get_vapp(@id)
      end
      vapp
    end

    def running? vapp
      vapp[:status].to_i == 4 ? true : false
    end

    private

    def build_network_config networks
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
