module Vcloud
  class FogModelInterface
    def initialize
      @vcloud = Fog::Compute::VcloudDirector.new
    end

    def org_name
      @vcloud.org_name
    end

    def current_organization
      @vcloud.organizations.get_by_name org_name
    end

    def current_vdc vdc_id
      current_organization.vdcs.detect {|v| v.id == vdc_id }
    end

    def get_vm_by_href href
      vm = @vcloud.get_vms_in_lease_from_query(
          {
              :filter => "href==#{href}"
          }).body[:VMRecord].first
      return nil unless vm
      vdc = current_vdc(vm[:vdc].split('/').last)
      vapp = vdc.vapps.get_by_name(vm[:containerName])
      vapp.vms.first
    end

  end
end