require 'rubygems'

class FogInterface < DelegateClass(Fog::Compute::VcloudDirector)

  attr_accessor :vcloud

  def initialize credential = :default
    ::Fog.credential = credential
    self.vcloud = SimpleDelegator.new(Fog::Compute::VcloudDirector.new)
  end


  #def_delegators :vcloud, :put_cpu, :put_memory, :process_task, :put_network_connection_system_section_vapp

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
    p "***********"
    #vapp = @vcloud.post_instantiate_vapp_template(extract_id(vdc), template,name,  params).body
    #@vcloud.process_task(vapp[:Tasks][:Task])
    #@vcloud.get_vapp( extract_id(vapp))
    vcloud.get_vapp('vapp-3e10c403-0862-4b7c-9ebf-8bf4dd9f8df6')
  end

  def put_memory vm_id, memory
    task = vcloud.put_memory(vm_id, memory).body
    vcloud.process_task(task)
  end

  def get_vapp id
    vcloud.get_vapp(id).body
  end

  def put_cpu vm_id, cpu
    task = vcloud.put_cpu(vm_id, cpu).body
    vcloud.process_task(task)
  end

  def put_network_connection_system_section_vapp vm_id, section
    task = vcloud.put_network_connection_system_section_vapp( vm_id, section).body
    vcloud.process_task(task)
  end

  def delete_vapp vapp_id
    task = vcloud.delete_vapp(vapp_id).body
    vcloud.process_task(task)
  end

  def find_networks network_names , vdc_name
    networks = []
    network_names.each do |network|
      if network.nil?
        networks << nil
      else
        link = vdc(vdc_name)[:AvailableNetworks][:Network].detect do |l|
          l[:type] == 'application/vnd.vmware.vcloud.network+xml' && l[:name] == network
        end
        networks << link
      end
    end
    networks
  end

  def extract_id(link)
    link[:href].split('/').last
  end

  def get_vm id
    org = vcloud.organizations.get_by_name(vcloud.org_name)
    vdc = org.vdcs.get(vdc[:href].split('/').last)
    disks = vdc.vapps.get(vapp_id).vms.get(vm_id).disks
  end
end
