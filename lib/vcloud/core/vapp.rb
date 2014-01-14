module Vcloud
  module Core
    class Vapp
      extend ComputeMetadata

      attr_reader :id

      def initialize(id)
        unless id =~ /^#{self.class.id_prefix}-[-0-9a-f]+$/
          raise "#{self.class.id_prefix} id : #{id} is not in correct format"
        end
        @id = id
      end

      def self.get_by_name(name)
        q = Query.new('vApp', :filter => "name==#{name}")
        unless res = q.get_all_results
          raise "Error finding vApp by name #{name}"
        end
        case res.size
        when 0
          raise "vApp #{name} not found"
        when 1
          return self.new(res.first[:href].split('/').last)
        else
          raise "found multiple vApp entities with name #{name}!"
        end
      end

      def vcloud_attributes
        Vcloud::Fog::ServiceInterface.new.get_vapp(id)
      end

      module STATUS
        RUNNING = 4
      end

      def name
        vcloud_attributes[:name]
      end

      def href
        vcloud_attributes[:href]
      end

      def vdc_id
        link = vcloud_attributes[:Link].detect { |l| l[:rel] == Fog::RELATION::PARENT && l[:type] == Fog::ContentTypes::VDC }
        link ? link[:href].split('/').last : raise('a vapp without parent vdc found')
      end

      def fog_vms
        vcloud_attributes[:Children][:Vm]
      end

      def networks
        vcloud_attributes[:'ovf:NetworkSection'][:'ovf:Network']
      end

      def self.get_by_name_and_vdc_name(name, vdc_name)
        fog_interface = Vcloud::Fog::ServiceInterface.new
        attrs = fog_interface.get_vapp_by_name_and_vdc_name(name, vdc_name)
        self.new(attrs[:href].split('/').last) if attrs && attrs.key?(:href)
      end

      def self.instantiate(name, network_names, template_id, vdc_name)
        Vcloud.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
        fog_interface = Vcloud::Fog::ServiceInterface.new
        networks = get_networks(network_names, vdc_name)

        attrs = fog_interface.post_instantiate_vapp_template(
            fog_interface.vdc(vdc_name),
            template_id,
            name,
            InstantiationParams: build_network_config(networks)
        )
        self.new(attrs[:href].split('/').last) if attrs and attrs.key?(:href)
      end

      def power_on
        raise "Cannot power on a missing vApp." unless id
        return true if running?
        Vcloud::Fog::ServiceInterface.new.power_on_vapp(id)
        running?
      end

      private
      def running?
        raise "Cannot call running? on a missing vApp." unless id
        vapp = Vcloud::Fog::ServiceInterface.new.get_vapp(id)
        vapp[:status].to_i == STATUS::RUNNING ? true : false
      end

      def self.build_network_config(networks)
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

      def self.id_prefix
        'vapp'
      end

      def self.get_networks(network_names, vdc_name)
        fsi = Vcloud::Fog::ServiceInterface.new
        fsi.find_networks(network_names, vdc_name) if network_names
      end
    end
  end
end
