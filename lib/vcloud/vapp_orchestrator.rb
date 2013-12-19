module Vcloud
  class VappOrchestrator

    def self.provision(vapp_config)
      name, vdc_name = vapp_config[:name], vapp_config[:vdc_name]
      begin
        if vapp = Vcloud::Core::Vapp.get_by_name_and_vdc_name(name, vdc_name)
          Vcloud.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
        else
          template = Vcloud::Core::VappTemplate.get(vapp_config[:catalog], vapp_config[:catalog_item])
          template_id = template.id

          network_names = extract_vm_networks(vapp_config)
          vapp = Vcloud::Core::Vapp.new.instantiate(name, network_names, template_id, vdc_name)
          Vcloud::Core::VmOrchestrator.new(vapp.fog_vms.first, vapp).customize(vapp_config[:vm]) if vapp_config[:vm]
          vapp.reload
        end

      rescue RuntimeError => e
        Vcloud.logger.error("Could not provision vApp: #{e.message}")
      end
      vapp
    end

    def self.extract_vm_networks(config)
      if (config[:vm] && config[:vm][:network_connections])
        config[:vm][:network_connections].collect { |h| h[:name] }
      end
    end

  end
end
