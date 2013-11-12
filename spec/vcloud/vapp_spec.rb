require 'spec_helper'

module Vcloud

  describe Vcloud::Vapp do

    before(:each) do
      @mock_fog_interface = double(:fog_interface)
      @mock_vdc = double(:vdc)
      @mock_vdc.stub(:name).and_return('Test vDC 1')
      @mock_fog_interface.stub(:vdc_object_by_name).and_return(@mock_vdc)
      @mock_fog_interface.stub(:template).and_return({:href => 
                         '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde' })
      @mock_fog_interface.stub(:find_networks).and_return([{
        :name => 'org-vdc-1-net-1',
        :href => '/org-vdc-1-net-1-id',
      }])
      @mock_model_vapp = double(:model_vapp)
      @mock_model_vapp.stub(:id).and_return('1')
      @mock_fog_interface.stub(:get_vapp).and_return({:name => 'test-vapp-1' })
      @mock_fog_interface.stub(:vdc).and_return({ })
      @mock_fog_request_vapp = {
        :href => '/test-vapp-1-id',
        :Children => {
          :Vm => ['bogus vm data']
        }
      }
      @mock_fog_interface.stub(:post_instantiate_vapp_template).and_return(@mock_fog_request_vapp)
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
          Vcloud.logger.should_receive(:info)
          vapp = Vcloud::Vapp.new @mock_fog_interface
          actual_vapp = vapp.provision config
          expect(actual_vapp).not_to be_empty
        end

        it "should create a vapp if it does not exist" do
          @mock_vm = double(:vm)
          @mock_vm.stub(:customize).and_return(nil)
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
          Vcloud.logger.should_receive(:info)
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
