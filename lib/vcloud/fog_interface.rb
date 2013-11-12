module Vcloud

  class FogInterface
    attr_accessor :vcloud

    def initialize
      self.vcloud = Fog::Compute::VcloudDirector.new
    end

    def org
      link = session[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
        l[:rel] == 'down' && l[:type] == Vcloud::ContentTypes::ORG
      end
      vcloud.get_organization(link[:href].split('/').last).body
    end

    def vdc_object_by_name vdc_name
       org = vcloud.organizations.get_by_name(vcloud.org_name)
       org.vdcs.get_by_name vdc_name
    end

    def catalog name
      link = org[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
        l[:type] == Vcloud::ContentTypes::CATALOG && l[:name] == name
      end
      vcloud.get_catalog(extract_id(link)).body
    end

    def vdc name
      link = org[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
        l[:type] == Vcloud::ContentTypes::VDC && l[:name] == name
      end
      vcloud.get_vdc(link[:href].split('/').last).body
    end

    def template catalog_name, template_name
      link = catalog(catalog_name)[:CatalogItems][:CatalogItem].detect do |l|
        l[:type] == Vcloud::ContentTypes::CATALOG_ITEM && l[:name].match(template_name)
      end
      if link.nil?
        Vcloud.logger.warn("Template #{template_name} not found in catalog #{catalog_name}")
        return nil
      end
      catalog_item = vcloud.get_catalog_item(extract_id(link)).body
      catalog_item[:Entity]
    end

    def session
      vcloud.get_current_session.body
    end

    def post_instantiate_vapp_template vdc, template, name, params
      Vcloud.logger.info("instantiating #{name} vapp in #{vdc[:name]}")
      vapp = vcloud.post_instantiate_vapp_template(extract_id(vdc), template, name,  params).body
      vcloud.process_task(vapp[:Tasks][:Task])
      vcloud.get_vapp( extract_id(vapp)).body
    end

    def put_memory vm_id, memory
      Vcloud.logger.info("putting #{memory}KB memory into VM #{vm_id}")
      task = vcloud.put_memory(vm_id, memory).body
      vcloud.process_task(task)
    end

    def get_vapp id
      vcloud.get_vapp(id).body
    end

    def get_vapp_by_vdc_and_name(vdc, name)
      vdc.vapps.get_by_name(name)
    end

    def put_cpu vm_id, cpu
      Vcloud.logger.info("putting #{cpu} CPU(s) into VM #{vm_id}")
      task = vcloud.put_cpu(vm_id, cpu).body
      vcloud.process_task(task)
    end

    def put_network_connection_system_section_vapp vm_id, section
      Vcloud.logger.info("adding NIC into VM #{vm_id}")
      task = vcloud.put_network_connection_system_section_vapp(vm_id, section).body
      vcloud.process_task(task)
    end

    def organizations
      vcloud.organizations
    end

    def org_name
      vcloud.org_name
    end

    def delete_vapp vapp_id
      task = vcloud.delete_vapp(vapp_id).body
      vcloud.process_task(task)
    end

    def power_off_vapp vapp_id
      task = vcloud.post_power_off_vapp(vapp_id).body
      vcloud.process_task(task)
    end

    def power_on_vapp vapp_id
      task = vcloud.post_power_on_vapp(vapp_id).body
      vcloud.process_task(task)
    end

    def shutdown_vapp vapp_id
      task = vcloud.post_shutdown_vapp(vapp_id).body
      vcloud.process_task(task)
    end

    def find_networks network_names , vdc_name
      network_names.collect do |network|
        vdc(vdc_name)[:AvailableNetworks][:Network].detect do |l|
          l[:type] == Vcloud::ContentTypes::NETWORK && l[:name] == network
        end
      end
    end

    def get_vapp_metadata_hash(id)
      metadata = {}
      @vcloud.get_vapp_metadata(id).body[:MetadataEntry].each do |entry|
        next unless entry[:type] == 'application/vnd.vmware.vcloud.metadata.value+xml'
        key = entry[:Key].to_sym
        val = entry[:TypedValue][:Value]
        case entry[:TypedValue][:xsi_type]
        when 'MetadataNumberValue'
          val = val.to_i
        when 'MetadataStringValue'
          val = val.to_s
        when 'MetadataDateTimeValue'
          val = DateTime.parse(val)
        when 'MetadataBooleanValue'
          val = val == 'true' ? true : false
        end
        metadata[key] = val
      end
      metadata
    end

    def get_vapp_metadata_by_key(id, key)
      @vcloud.get_vapp_metadata_item_metadata(id, key.to_s)
    end

    def put_vapp_metadata_value(id, k, v)
      Vcloud.logger.info("putting metadata pair '#{k}'=>'#{v}' to #{id}")
      # need to convert key to_s since Fog 0.17 borks on symbol key
      task = @vcloud.put_vapp_metadata_item_metadata(id, k.to_s, v).body
      @vcloud.process_task(task)
    end

    def put_guest_customization_section vm_id, vm_name, script
      Vcloud.logger.info("configuring guest customization section for vm : #{vm_id}")
      task = vcloud.put_guest_customization_section_vapp(vm_id, {
          :Enabled => true,
          :CustomizationScript => script,
          :ComputerName => vm_name
      }).body
      vcloud.process_task(task)
    end

    private
    def extract_id(link)
      link[:href].split('/').last
    end

  end

end
