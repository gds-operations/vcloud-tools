module Vcloud
  class VmOrchestrator
    def initialize fog_vm, vapp
      vm_id = fog_vm[:href].split('/').last
      @vm = Core::Vm.new(vm_id, vapp)
    end

    def customize(vm_config)
      @vm.update_name(@vm.vapp_name)
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

    def self.customize_schema
      {
        type: 'hash',
        required: false,
        allowed_empty: false,
        internals: {
          network_connections: {
            type: 'array',
            required: false,
            each_element_is: {
              type: 'hash',
              internals: {
                name: { type: 'string', required: true },
                ip_address: { type: 'ip_address', required: false },
              },
            },
          },
          storage_profile: { type: 'string', required: false },
          hardware_config: {
            type: 'hash',
            required: false,
            internals: {
              cpu: { type: 'string_or_number', required: false },
              memory: { type: 'string_or_number', required: false },
            },
          },
          extra_disks: {
            type: 'array',
            required: false,
            allowed_empty: false,
            each_element_is: {
              type: 'hash',
              internals: {
                name: { type: 'string', required: false },
                size: { type: 'string_or_number', required: false },
              },
            },
          },
          bootstrap:   {
            type: 'hash',
            required: false,
            allowed_empty: false,
            internals: {
              script_path: { type: 'string', required: false },
              script_post_processor: { type: 'string', required: false },
              vars: { type: 'hash', required: false, allowed_empty: true },
            },
          },
          metadata: {
            type: 'hash',
            required: false,
            allowed_empty: true,
          },
        },
      }
    end

  end
end
