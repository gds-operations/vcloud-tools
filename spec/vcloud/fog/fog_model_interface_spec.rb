require 'spec_helper'

describe Vcloud::Fog::ModelInterface do

  it "should retrive logged in organization" do
    vm_href, vdc_href = 'https://vmware.net/vapp/vm-1', 'vdc/vdc-1'
    vm = double(:vm, :href => vm_href)
    vdc = double(:vdc1,
                 :id => 'vdc-1',
                 :href => vdc_href,
                 :vapps => double(:vapps, :get_by_name => double(:vapp, :name => 'vapp-1', :vms => [vm])))
    org = double(:hr, :name => 'HR ORG', :vdcs => [vdc])

    vcloud = double(:mock_vcloud, :org_name => 'HR', :organizations => double(:orgs, :get_by_name => org))
    vcloud.should_receive(:get_vms_in_lease_from_query).with({:filter => "href==#{vm_href}"}).and_return(
        double(
            :vm_query_record,
            :body => {:VMRecord => [{:href => vm_href, :containerName => 'vapp-1', :vdc => vdc_href}]}
        )
    )
    Fog::Compute::VcloudDirector.should_receive(:new).and_return(vcloud)

    Vcloud::Fog::ModelInterface.new.get_vm_by_href(vm_href).should == vm
  end
end