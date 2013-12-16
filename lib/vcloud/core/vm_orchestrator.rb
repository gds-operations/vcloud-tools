module Vcloud
  module Core
    class VmOrchestrator
      def initialize vm, vapp
        @vm = Vm.new(vm, vapp)
      end

      def customize(vm_config)
        @vm.configure_network_interfaces vm_config[:network_connections]
        @vm.update_storage_profile(vm_config[:storage_profile]) if vm_config[:storage_profile]
        if hardware_config = vm_config[:hardware_config]
          @vm.update_cpu_count(hardware_config[:cpu])
          @vm.update_memory_size_in_mb(hardware_config[:memory])
        end
        @vm.add_extra_disks(vm_config[:extra_disks])
        @vm.update_metadata(vm_config[:metadata])
        @vm.configure_guest_customization_section(
            @vm.vapp_name,
            vm_config[:bootstrap],
            vm_config[:extra_disks]
        )
      end

    end
  end
end