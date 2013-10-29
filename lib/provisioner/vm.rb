module Provisioner
  class Vm

    attr_accessor :fog_interface, :vm, :id, :vapp_id

    def initialize fog_interface, vm , vapp_id
      self.vm = vm
      self.id = vm[:href].split('/').last
      self.fog_interface = fog_interface
      self.vapp_id = vapp_id
    end

    def customize config, vdc_name
      networks = fog_interface.find_networks(config["networks"], vdc_name)

      hardware_config = config['hardware_config']

      configure_network_interface id,networks , config['ip_address']
      if hardware_config
        put_cpu(hardware_config['cpu'])
        put_memory(hardware_config['memory'])
      end
      add_extra_disks(config['disks'], vdc_name)
    end


    def put_memory(new_memory)
      unless memory.to_i == new_memory
        fog_interface.put_memory(id, new_memory)
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

    def put_cpu(new_cpu)
      unless cpu.to_i == new_cpu
        fog_interface.put_cpu(id, new_cpu)
      end
    end

    def add_extra_disks extra_disks, vdc_name
      org = fog_interface.organizations.get_by_name(fog_interface.org_name)
      vdc = org.vdcs.get_by_name(vdc_name)
      vapp = vdc.vapps.get(vapp_id)
      vm = vapp.vms.first
      if extra_disks
        extra_disks.each do |extra_disk|
          vm.disks.create(extra_disk[:size])
        end
      end
    end

    def configure_network_interface id, networks, machine_ip
      section = {PrimaryNetworkConnectionIndex: 0}
      section[:NetworkConnection] = networks.compact.each_with_index.map do |network, i|
        connection = {
            network: network[:name],
            needsCustomization: true,
            NetworkConnectionIndex: i,
            IsConnected: true
        }
        ip_address = machine_ip
        connection[:IpAddress] = ip_address unless ip_address.nil?
        connection[:IpAddressAllocationMode] = ip_address ? 'MANUAL' : 'DHCP'
        connection
      end
      @fog_interface.put_network_connection_system_section_vapp(id, section)
    end

    private

    def virtual_hardware_section
      vm[:'ovf:VirtualHardwareSection'][:'ovf:Item']
    end


  end
end