module Vcloud
  module Core
    class Vapp < Entity
      extend ComputeMetadata

      attr_reader :vcloud_attributes

      def initialize(vcloud_attributes = {})
        @vcloud_attributes = vcloud_attributes
        @fog_interface = Vcloud::Fog::ServiceInterface.new
      end

      module STATUS
        RUNNING = 4
      end

      def name
        @vcloud_attributes[:name]
      end

      def vdc_id
        link = @vcloud_attributes[:Link].detect { |l| l[:rel] == Fog::RELATION::PARENT && l[:type] == Fog::ContentTypes::VDC }
        link ? link[:href].split('/').last : raise('a vapp without parent vdc found')
      end

      def fog_vms
        @vcloud_attributes[:Children][:Vm]
      end

      def networks
        @vcloud_attributes[:'ovf:NetworkSection'][:'ovf:Network']
      end

      def self.get_by_name_and_vdc_name(name, vdc_name)
        fog_interface = Vcloud::Fog::ServiceInterface.new
        vcloud_attributes = fog_interface.get_vapp_by_name_and_vdc_name(name, vdc_name)
        new(vcloud_attributes) if vcloud_attributes
      end

      def reload
        @fog_interface.get_vapp(id)
      end

      def instantiate(name, network_names, template_id, vdc_name)
        Vcloud.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
        networks = get_networks(network_names, vdc_name)

        @vcloud_attributes = @fog_interface.post_instantiate_vapp_template(
            @fog_interface.vdc(vdc_name),
            template_id,
            name,
            InstantiationParams: build_network_config(networks)
        )
        self
      end

      def power_on
        raise "Cannot power on a missing vApp." unless id
        return true if running?
        @fog_interface.power_on_vapp(id)
        running?
      end

      private
      def running?
        raise "Cannot call running? on a missing vApp." unless id
        vapp = @fog_interface.get_vapp(id)
        vapp[:status].to_i == STATUS::RUNNING ? true : false
      end

      def build_network_config(networks)
        return {} unless networks
        instantiation = { NetworkConfigSection: {NetworkConfig: []} }
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

      def get_networks(network_names, vdc_name)
        @fog_interface.find_networks(network_names, vdc_name) if network_names
      end
    end
  end
end
