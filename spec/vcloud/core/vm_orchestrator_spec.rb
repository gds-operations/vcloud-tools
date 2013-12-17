require 'spec_helper'

module Vcloud
  module Core
    describe VmOrchestrator do

      it "orchestrate customization" do
        vm_config = {
            :hardware_config => {
                :memory => 4096,
                :cpu => 2
            },
            :metadata => {
                :shutdown => true
            },
            :extra_disks => [
                {:size => '1024', :name => 'Hard disk 2', :fs_file => 'mysql', :fs_mntops => 'mysql-something'},
                {:size => '2048', :name => 'Hard disk 3', :fs_file => 'solr', :fs_mntops => 'solr-something'}
            ],

            :network_connections => [
                {:name => "network1", :ip_address => "198.12.1.21"},
            ],
            :bootstrap => {
                :script_path => '/tmp/boostrap.erb',
                :vars => {
                    :message => 'hello world'
                }
            },
            :storage_profile => {
                :name => 'basic-storage',
                :href => 'https://vcloud.example.net/api/vdcStorageProfile/000aea1e-a5e9-4dd1-a028-40db8c98d237'
            }
        }
        fog_vm = { :href => '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237' }
        vapp = double(:vapp, :name => 'web-app1')
        vm = double(:vm, :vapp_name => 'web-app1', :vapp => vapp, :name => 'test-vm-1')
        Vm.should_receive(:new).and_return(vm)

        vm.should_receive(:name=).with('web-app1')
        vm.should_receive(:configure_network_interfaces).with(vm_config[:network_connections])
        vm.should_receive(:update_storage_profile).with(vm_config[:storage_profile])
        vm.should_receive(:update_cpu_count).with(2)
        vm.should_receive(:update_memory_size_in_mb).with(4096)
        vm.should_receive(:add_extra_disks).with(vm_config[:extra_disks])
        vm.should_receive(:update_metadata).with(vm_config[:metadata])
        vm.should_receive(:configure_guest_customization_section).with('web-app1', vm_config[:bootstrap], vm_config[:extra_disks])

        VmOrchestrator.new(fog_vm, vapp).customize(vm_config)
      end
    end
  end
end
