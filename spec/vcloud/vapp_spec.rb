require 'spec_helper'
require 'stub_fog_interface'

module Vcloud

  describe Vcloud::Vapp do

    before(:each) do
      @mock_fog_interface = StubFogInterface.new
      @mock_model_vapp = double(:model_vapp)
      @mock_model_vapp.stub(:id).and_return('1')
    end

    describe '#power_on' do
      context "powering on a vapp" do

        config = {
          :name     => 'test-vapp-1',
          :vdc_name => 'Test vDC 1',
        }

        it "should power on a vapp that is not powered on" do
          vapp = Vcloud::Vapp.new @mock_fog_interface, config
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
          @mock_fog_interface.should_receive(:power_on_vapp).with(vapp.id)
          state = vapp.power_on
          expect(state) == true
        end

        it "should not power on a vapp that is already powered on, but should return true" do
          vapp = Vcloud::Vapp.new @mock_fog_interface, config
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
          @mock_fog_interface.stub(:get_vapp).and_return({:status => 4})
          @mock_fog_interface.should_not_receive(:power_on_vapp)
          state = vapp.power_on
          expect(state) == true
        end

        it "should raise an error if vapp does not exist" do
          vapp = Vcloud::Vapp.new @mock_fog_interface, config
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
          expect { vapp.power_on }.to raise_exception(RuntimeError, 'Cannot power on a missing vApp.')
        end

      end
    end

    describe '#provision' do
      context "provisioning a vapp" do
        config = {
          :name     => 'test-vapp-1',
          :vdc_name => 'Test vDC 1',
          :catalog  => 'org1-catalog',
          :catalog_item => 'org1-template',
          :vm => {
            :network_connections => [{:name => 'org-vdc-1-net-1' }]
          }
        }

        it "should return a vapp if it already exists" do
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
          #Vcloud.logger.should_receive(:info)
          vapp = Vcloud::Vapp.new @mock_fog_interface
          actual_vapp = vapp.provision config
          expect(actual_vapp).not_to be_empty
        end

        it "should create a vapp if it does not exist" do
          @mock_vm = double(:vm)
          @mock_vm.stub(:customize).and_return(nil)
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
          #Vcloud.logger.should_receive(:info)
          Vm.stub(:new) { @mock_vm }
          vapp = Vcloud::Vapp.new @mock_fog_interface
          actual_vapp = vapp.provision config
          expect(actual_vapp).not_to be_empty
          #TODO some detail of the actual vapp?
        end

        it "should log the error and move on if there is no template" do
          @mock_fog_interface.stub(:template).and_return(nil)
          vapp = Vcloud::Vapp.new @mock_fog_interface
          Vcloud.logger.should_receive(:error).with("Could not provision vApp: Could not find template vApp.")
          vapp.provision config
        end

      end
    end

  end
end
