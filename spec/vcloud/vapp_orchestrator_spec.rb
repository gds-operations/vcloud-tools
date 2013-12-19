require 'spec_helper'

module Vcloud

  describe VappOrchestrator do

    context "provision a vapp" do

      before(:all) do
        @config = {
            :name => 'test-vapp-1',
            :vdc_name => 'test-vdc-1',
            :catalog => 'org-1-catalog',
            :catalog_item => 'org-1-template',
            :vm => {
                :network_connections => [{:name => 'org-vdc-1-net-1'}]
            }
        }
      end

      it "should return a vapp if it already exists" do
        existing_vapp = double(:vapp, :name => 'existing-vapp-1')

        Core::Vapp.should_receive(:get_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').and_return(existing_vapp)
        actual_vapp = VappOrchestrator.provision @config
        actual_vapp.should_not be_nil
        actual_vapp.should == existing_vapp
      end

      it "should create a vapp if it does not exist" do
        #this test highlights the problems in vapp
        mock_fog_vm = double(:vm)
        mock_vapp = double(:vapp, :fog_vms => [mock_fog_vm], :reload => self)
        mock_vm_orchestrator = double(:vm_orchestrator, :customize => true)


        Core::Vapp.should_receive(:get_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').and_return(nil)
        Core::VappTemplate.should_receive(:get).with('org-1-catalog', 'org-1-template').and_return(double(:vapp_template, :id => 1))

        Core::Vapp.any_instance.should_receive(:instantiate).with('test-vapp-1', ['org-vdc-1-net-1'], 1, 'test-vdc-1')
        .and_return(mock_vapp)
        Core::VmOrchestrator.should_receive(:new).with(mock_fog_vm, mock_vapp).and_return(mock_vm_orchestrator)

        new_vapp = VappOrchestrator.provision @config
        new_vapp.should == mock_vapp
      end

      it "should log the error and swallow the exception if there is no template" do
        Core::Vapp.should_receive(:get_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').and_return(nil)
        Core::VappTemplate.should_receive(:get).with('org-1-catalog', 'org-1-template').and_raise('Could not find template vApp')

        Vcloud.logger.should_receive(:error).with("Could not provision vApp: Could not find template vApp")
        VappOrchestrator.provision @config
      end

    end
  end
end

