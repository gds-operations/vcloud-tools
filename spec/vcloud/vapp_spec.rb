require 'spec_helper'

module Vcloud

  describe Vcloud::Vapp do

    before(:each) do
      @mock_fog_interface = double(:fog_interface)
      @mock_vdc = double(:vdc)
      @mock_vdc.stub(:name).and_return('dan')
      @mock_fog_interface.stub(:vdc_object_by_name).and_return(@mock_vdc)
      @mock_fog_interface.stub(:template).and_return({:href => '/carl' })
      @mock_fog_interface.stub(:find_networks).and_return([{
        :name => 'charlotte',
        :href => '/charlotte',
      }])
      @mock_model_vapp = double(:model_vapp)
      @mock_model_vapp.stub(:id).and_return('1')
      @mock_fog_interface.stub(:get_vapp).and_return({:name => 'sneha' })
      @mock_fog_interface.stub(:vdc).and_return({ })
      @mock_fog_request_vapp = {
        :href => '/sam',
        :Children => {
          :Vm => ['hello']
        }
      }
      @mock_fog_interface.stub(:post_instantiate_vapp_template).and_return(@mock_fog_request_vapp)
    end

    describe '#provision' do
      context "provisioning a vapp" do
        config = {
          :name     => 'mike',
          :vdc_name => 'anna',
          :catalog  => 'bob',
          :catalog_item => 'andrew',
          :vm => {
            :network_connections => [{:name => 'charlotte' }]
          }
        }
        it "should return a vapp if it already exists" do
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
          vapp = Vcloud::Vapp.new @mock_fog_interface
          actual_vapp = vapp.provision config
          expect(actual_vapp).not_to be_empty
        end

        it "should create a vapp if it does not exist" do
          @mock_vm = double(:vm)
          @mock_vm.stub(:customize).and_return(nil)
          @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
          Vm.stub(:new) { @mock_vm }
          vapp = Vcloud::Vapp.new @mock_fog_interface
          actual_vapp = vapp.provision config
          expect(actual_vapp).not_to be_empty
          #TODO some detail of the actual vapp?
        end

      end
    end

  end
end
