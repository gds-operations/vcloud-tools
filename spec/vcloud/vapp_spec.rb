require 'spec_helper'


module Vcloud

  describe Vcloud::Vapp do

    context "attributes" do
      before(:all) {
        attributes = {
            :name => "Webserver vapp-1",
            :Link => [{
                          :rel => "up",
                          :type => "application/vnd.vmware.vcloud.vdc+xml",
                          :href => "https://api.vcd.portal.skyscapecloud.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237"
                      }]
        }
        @vapp = Vcloud::Vapp.new(@mock_fog_interface, attributes)
      }
      it { @vapp.should respond_to(:attributes) }
      it { @vapp.name.should == "Webserver vapp-1" }

      context "vapp should have parent vdc" do
        it "should load parent vdc id from fog attributes" do
          @vapp.vdc_id.should == '074aea1e-a5e9-4dd1-a028-40db8c98d237'
        end

        it "should raise error if vapp without parent vdc found" do
          vapp_without_vdc = Vcloud::Vapp.new(@mock_fog_interface, {:Link => []})
          lambda { vapp_without_vdc.vdc_id }.should raise_error('a vapp without parent vdc found')
        end
      end
    end

    before(:each) do
      @fog_vapp_body = {
          :name => "Webserver vapp-1",
          :href => "https://api.vcd.portal.skyscapecloud.com/api/vApp/vapp-63d3be58-2d5c-477d-8410-267e7c3c4a02",
          :Link => [{
                        :rel => "up",
                        :type => "application/vnd.vmware.vcloud.vdc+xml",
                        :href => "https://api.vcd.portal.skyscapecloud.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237"
                    }]
      }
      @mock_fog_interface = double(:fog_interface)
      @mock_vdc = double(:vdc)
      @mock_vdc.stub(:name).and_return('Test vDC 1')
      @mock_fog_interface.stub(:vdc_object_by_name).and_return(@mock_vdc)
      @mock_fog_interface.stub(:template).and_return({:href =>
                                                          '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde'})
      @mock_fog_interface.stub(:find_networks).and_return([{
                                                               :name => 'org-vdc-1-net-1',
                                                               :href => '/org-vdc-1-net-1-id',
                                                           }])
      @mock_model_vapp = double(:model_vapp)
      @mock_model_vapp.stub(:id).and_return('1')
      @mock_fog_interface.stub(:get_vapp).and_return({:name => 'test-vapp-1'})
      @mock_fog_interface.stub(:vdc).and_return({})
      @mock_fog_request_vapp = {
          :href => '/test-vapp-1-id',
          :Children => {
              :Vm => ['bogus vm data']
          }
      }
      @mock_fog_interface.stub(:post_instantiate_vapp_template).and_return(@mock_fog_request_vapp)
    end


    context "powering on a vapp" do

      #config = {
      #    :name => 'test-vapp-1',
      #    :vdc_name => 'Test vDC 1',
      #}

      it "should power on a vapp that is not powered on" do
        vapp = Vcloud::Vapp.new @mock_fog_interface, @fog_vapp_body
        @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
        @mock_fog_interface.should_receive(:power_on_vapp).with(vapp.id)
        state = vapp.power_on
        expect(state) == true
      end

      it "should not power on a vapp that is already powered on, but should return true" do
        vapp = Vcloud::Vapp.new @mock_fog_interface, @fog_vapp_body
        @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
        @mock_fog_interface.stub(:get_vapp).and_return({:status => 4})
        @mock_fog_interface.should_not_receive(:power_on_vapp)
        state = vapp.power_on
        expect(state) == true
      end

      it "should raise an error if vapp does not exist" do
        vapp = Vcloud::Vapp.new @mock_fog_interface, {}
        @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
        expect { vapp.power_on }.to raise_exception(RuntimeError, 'Cannot power on a missing vApp.')
      end

    end

    context "provisioning a vapp" do
      config = {
          :name => 'test-vapp-1',
          :vdc_name => 'Test vDC 1',
          :catalog => 'org1-catalog',
          :catalog_item => 'org1-template',
          :vm => {
              :network_connections => [{:name => 'org-vdc-1-net-1'}]
          }
      }

      it "should return a vapp if it already exists" do
        @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(@mock_model_vapp)
        Vcloud.logger.should_receive(:info)
        vapp = Vcloud::Vapp.new @mock_fog_interface, @fog_vapp_body
        actual_vapp = vapp.provision config
        expect(actual_vapp).not_to be_empty
      end

      it "should create a vapp if it does not exist" do
        @mock_vm = double(:vm)
        @mock_vm.stub(:customize).and_return(nil)
        @mock_fog_interface.stub(:get_vapp_by_vdc_and_name).and_return(nil)
        Vcloud.logger.should_receive(:info)
        Vm.stub(:new) { @mock_vm }
        vapp = Vcloud::Vapp.new @mock_fog_interface, @fog_vapp_body
        actual_vapp = vapp.provision config
        expect(actual_vapp).not_to be_empty
        #TODO some detail of the actual vapp?
      end

      it "should log the error and move on if there is no template" do
        @mock_fog_interface.stub(:template).and_return(nil)
        vapp = Vcloud::Vapp.new @mock_fog_interface, @fog_vapp_body
        Vcloud.logger.should_receive(:error).with("Could not provision vApp: Could not find template vApp.")
        vapp.provision config
      end

    end

  end
end
