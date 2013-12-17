module Vcloud
  module Core
    class Vm < Entity
      extend ComputeMetadata

      attr_reader :vcloud_attributes

      def initialize(vcloud_attributes, vapp)
        @vcloud_attributes = vcloud_attributes
        @fog_interface = Vcloud::Fog::ServiceInterface.new
        @vapp = vapp
      end

      def update_memory_size_in_mb(new_memory)
        return if new_memory.nil?
        return if new_memory.to_i < 64
        unless memory.to_i == new_memory.to_i
          @fog_interface.put_memory(id, new_memory)
        end
      end

      def memory
        memory_item = virtual_hardware_section.detect { |i| i[:'rasd:ResourceType'] == '4' }
        memory_item[:'rasd:VirtualQuantity']
      end

      def cpu
        cpu_item = virtual_hardware_section.detect { |i| i[:'rasd:ResourceType'] == '3' }
        cpu_item[:'rasd:VirtualQuantity']
      end

      def vapp_name
        @vapp.name
      end

      def update_cpu_count(new_cpu_count)
        return if new_cpu_count.nil?
        return if new_cpu_count.to_i == 0
        unless cpu.to_i == new_cpu_count.to_i
          @fog_interface.put_cpu(id, new_cpu_count)
        end
      end

      def update_metadata(metadata)
        return if metadata.nil?
        metadata.each do |k, v|
          @fog_interface.put_vapp_metadata_value(@vapp.id, k, v)
          @fog_interface.put_vapp_metadata_value(id, k, v)
        end
      end

      def add_extra_disks(extra_disks)
        vm = Vcloud::Fog::ModelInterface.new.get_vm_by_href(@vcloud_attributes[:href])
        if extra_disks
          extra_disks.each do |extra_disk|
            Vcloud.logger.info("adding a disk of size #{extra_disk[:size]}MB into VM #{id}")
            vm.disks.create(extra_disk[:size])
          end
        end
      end

      def configure_network_interfaces(networks_config)
        return unless networks_config
        section = {PrimaryNetworkConnectionIndex: 0}
        section[:NetworkConnection] = networks_config.compact.each_with_index.map do |network, i|
          connection = {
              network: network[:name],
              needsCustomization: true,
              NetworkConnectionIndex: i,
              IsConnected: true
          }
          ip_address = network[:ip_address]
          connection[:IpAddress] = ip_address unless ip_address.nil?
          connection[:IpAddressAllocationMode] = ip_address ? 'MANUAL' : 'DHCP'
          connection
        end
        @fog_interface.put_network_connection_system_section_vapp(id, section)
      end

      def configure_guest_customization_section(name, bootstrap_config, extra_disks)
        if bootstrap_config.nil? or bootstrap_config[:script_path].nil?
          interpolated_preamble = ''
        else
          preamble_vars = bootstrap_config[:vars].merge(:extra_disks => extra_disks)
          interpolated_preamble = generate_preamble(
              bootstrap_config[:script_path],
              bootstrap_config[:script_post_processor],
              preamble_vars,
          )
        end
        @fog_interface.put_guest_customization_section(id, name, interpolated_preamble)
      end

      def generate_preamble(script_path, script_post_processor, vars)
        vapp_name = @vapp.name
        script = ERB.new(File.read(File.expand_path(script_path)), nil, '>-')
        .result(binding)
        if script_post_processor
          script = Open3.capture2(File.expand_path(script_post_processor),
                                  stdin_data: script).first
        end
        script
      end

      def update_storage_profile storage_profile
        if valid_storage_profile?(storage_profile)
          @fog_interface.put_vm(id, name, {:StorageProfile => storage_profile})
        else
          Vcloud.logger.info("bad storage profile: #{storage_profile}")
          false
        end
      end

      private
      def virtual_hardware_section
        @vcloud_attributes[:'ovf:VirtualHardwareSection'][:'ovf:Item']
      end

      def id_prefix
        'vm'
      end

      def valid_storage_profile?(storage_profile)
        storage_profile.key?(:name) && storage_profile.key?(:href)
      end

    end
  end
end
