class FogInterface
  attr_accessor :vcloud

  def initialize credential = :default
    ::Fog.credential = credential
    self.vcloud = Fog::Compute::VcloudDirector.new
  end

  def org
    link = session[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
      l[:rel] == 'down' && l[:type] == 'application/vnd.vmware.vcloud.org+xml'
    end
    vcloud.get_organization(link[:href].split('/').last).body
  end

  def catalog name
    link = org[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
      l[:type] == 'application/vnd.vmware.vcloud.catalog+xml' && l[:name] == name
    end
    vcloud.get_catalog(extract_id(link)).body
  end

  def vdc name
    link = org[:Link].select { |l| l[:rel] == 'down' }.detect do |l|
      l[:type] == 'application/vnd.vmware.vcloud.vdc+xml' && l[:name] == name
    end
    vcloud.get_vdc(link[:href].split('/').last).body
  end

  def template catalog_name, template_name
    link = catalog(catalog_name)[:CatalogItems][:CatalogItem].detect do |l|
      l[:type] == 'application/vnd.vmware.vcloud.catalogItem+xml' && l[:name].match(template_name)
    end
    catalog_item = vcloud.get_catalog_item(extract_id(link)).body
    catalog_item[:Entity]
  end

  def session
    vcloud.get_current_session.body
  end

  def post_instantiate_vapp_template vdc, template, name, params
    VCloud.logger.info("instantiating #{name} vapp in #{vdc[:name]}")
    #vapp = vcloud.post_instantiate_vapp_template(extract_id(vdc), template, name,  params).body
    #vcloud.process_task(vapp[:Tasks][:Task])
    #vcloud.get_vapp( extract_id(vapp))
    vcloud.get_vapp('vapp-9b5b5e82-58a4-43cc-977d-f94116a0610c')
  end

  def put_memory vm_id, memory
    VCloud.logger.info("putting #{memory}KB memory into VM #{vm_id}")
    task = vcloud.put_memory(vm_id, memory).body
    vcloud.process_task(task)
  end

  def get_vapp id
    vcloud.get_vapp(id).body
  end

  def put_cpu vm_id, cpu
    VCloud.logger.info("putting #{cpu} CPU(s) into VM #{vm_id}")
    task = vcloud.put_cpu(vm_id, cpu).body
    vcloud.process_task(task)
  end

  def put_network_connection_system_section_vapp vm_id, section
    VCloud.logger.info("adding NIC into VM #{vm_id}")
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

  def find_networks network_names , vdc_name
    network_names.collect do |network|
        link = vdc(vdc_name)[:AvailableNetworks][:Network].detect do |l|
          l[:type] == 'application/vnd.vmware.vcloud.network+xml' && l[:name] == network
        end
    end
  end

  private
  def extract_id(link)
    link[:href].split('/').last
  end
end
