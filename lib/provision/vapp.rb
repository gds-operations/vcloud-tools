module Provision
  class Vapp
    attr_accessor :fog_interface

    def initialize vcloud
      self.fog_interface = vcloud
    end

    def provision config, vdc_name, template
      networks = fog_interface.find_networks(config["networks"], vdc_name)
      vdc = fog_interface.vdc(vdc_name)
      vapp = fog_interface.post_instantiate_vapp_template(
          vdc,
          template[:href].split('/').last,
          config['name'],
          InstantiationParams: build_network_config(networks)
      ).body
      vm = Provision::Vm.new(fog_interface, vapp[:Children][:Vm].first)
      vm.customize(config)
      fog_interface.get_vapp(vapp[:href].split('/').last)
    end


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