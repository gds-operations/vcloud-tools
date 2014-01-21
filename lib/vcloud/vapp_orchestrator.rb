module Vcloud
  class VappOrchestrator

    def self.provision(vapp_config)
      name, vdc_name = vapp_config[:name], vapp_config[:vdc_name]

      if vapp = Vcloud::Core::Vapp.get_by_name_and_vdc_name(name, vdc_name)
        Vcloud.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
      else
        template = Vcloud::Core::VappTemplate.get(vapp_config[:catalog], vapp_config[:catalog_item])
        template_id = template.id

        network_names = extract_vm_networks(vapp_config)
        vapp = Vcloud::Core::Vapp.instantiate(name, network_names, template_id, vdc_name)
        Vcloud::VmOrchestrator.new(vapp.fog_vms.first, vapp).customize(vapp_config[:vm]) if vapp_config[:vm]
      end
      vapp
    end

    def self.provision_schema
      {
        type: 'hash',
        required: true,
        allowed_empty: false,
        internals: {
          name:      { type: 'string', required: true, allowed_empty: false },
          vdc_name:  { type: 'string', required: true, allowed_empty: false },
          catalog:   { type: 'string', required: true, allowed_empty: false },
          catalog_item: { type: 'string', required: true, allowed_empty: false },
          vm: Vcloud::VmOrchestrator.customize_schema,
        }
      }
    end

    def self.extract_vm_networks(config)
      if (config[:vm] && config[:vm][:network_connections])
        config[:vm][:network_connections].collect { |h| h[:name] }
      end
    end

  end
end
