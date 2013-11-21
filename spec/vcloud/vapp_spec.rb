require 'spec_helper'

describe Vcloud::Vapp do
  context "attributes" do
    before(:all) {
      attributes = {
          :name => "Webserver vapp-1",
          :Link => [{
                        :rel => "up",
                        :type => "application/vnd.vmware.vcloud.vdc+xml",
                        :href => "https://api.vcd.portal.skyscapecloud.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237"
                    }],
          :Children => {:Vm => [{:href => '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237'}]}
      }
      @vapp = Vcloud::Vapp.new(attributes)
    }
    it { @vapp.should respond_to(:vcloud_attributes) }
    it { @vapp.name.should == "Webserver vapp-1" }

    context "vapp should have parent vdc" do
      it "should load parent vdc id from fog attributes" do
        @vapp.vdc_id.should == '074aea1e-a5e9-4dd1-a028-40db8c98d237'
      end

      it "should raise error if vapp without parent vdc found" do
        vapp_without_vdc = Vcloud::Vapp.new({:Link => []})
        lambda { vapp_without_vdc.vdc_id }.should raise_error('a vapp without parent vdc found')
      end
    end

    it "should return vms" do
      @vapp.vms.count.should == 1
      @vapp.vms.first[:href].should == '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237'
    end
  end

  context "power on" do
    context "successful power on" do
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
        @mock_fog_interface = StubFogInterface.new
        Vcloud::FogServiceInterface.stub(:new).and_return(@mock_fog_interface)
      end

      it "should power on a vapp that is not powered on" do
        vapp = Vcloud::Vapp.new(@fog_vapp_body)
        @mock_fog_interface.should_receive(:get_vapp).twice().and_return({:status => 8})
        @mock_fog_interface.should_receive(:power_on_vapp).with(vapp.id)
        state = vapp.power_on
        expect(state) == true
      end

      it "should not power on a vapp that is already powered on, but should return true" do
        vapp = Vcloud::Vapp.new(@fog_vapp_body)
        @mock_fog_interface.should_receive(:get_vapp).and_return({:status => 4})
        @mock_fog_interface.should_not_receive(:power_on_vapp)
        state = vapp.power_on
        expect(state) == true
      end
    end

    context "raise error if vapp not found" do
      it "should raise an error if vapp does not exist" do
        vapp = Vcloud::Vapp.new({})
        expect { vapp.power_on }.to raise_exception(RuntimeError, 'Cannot power on a missing vApp.')
      end
    end
  end

  context "provisioning a vapp" do

    before(:each) do
      @fog_vapp_body ={
          :name => 'Test vDC 1',
          :href => 'https://api.vcd.portal.skyscapecloud.com/api/vApp/vapp-63d3be58-2d5c-477d-8410-267e7c3c4a02',
          :Link => [{
                        :rel => 'up',
                        :type => 'application/vnd.vmware.vcloud.vdc+xml',
                        :href => 'https://api.vcd.portal.skyscapecloud.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237'
                    }],
          :Children => {
              :Vm => ['bogus vm data']
          }
      }
      @mock_fog_interface = double(:fog_interface)
      @mock_fog_interface.stub(:find_networks).and_return([{
                                                               :name => 'org-vdc-1-net-1',
                                                               :href => '/org-vdc-1-net-1-id',
                                                           }])

      @mock_fog_interface.stub(:vdc).and_return({})
      @mock_fog_request_vapp = {
          :href => '/test-vapp-1-id',
          :Children => {
              :Vm => ['bogus vm data']
          },
          :name => 'test-vapp-1'
      }
      @mock_fog_interface.stub(:post_instantiate_vapp_template).and_return(@fog_vapp_body)
    end

    config = {
        :name => 'test-vapp-1',
        :vdc_name => 'test-vdc-1',
        :catalog => 'org-1-catalog',
        :catalog_item => 'org-1-template',
        :vm => {
            :network_connections => [{:name => 'org-vdc-1-net-1'}]
        }
    }

    it "should return a vapp if it already exists" do
      existing_vapp = {:name => 'existing-vapp-1'}
      @mock_fog_interface.should_receive(:get_vapp_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').
          and_return(existing_vapp)
      @mock_fog_interface.should_receive(:template).with("org-1-catalog", "org-1-template").and_return(
          {:href => '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde'})
      Vcloud::FogServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

      Vcloud.logger.should_receive(:info)
      actual_vapp = Vcloud::Vapp.new.provision config
      actual_vapp.should_not be_nil
      actual_vapp.name.should == 'existing-vapp-1'
    end

    it "should create a vapp if it does not exist" do
      @mock_vm = double(:vm)
      @mock_vm.stub(:customize).and_return(nil)
      @mock_fog_interface.should_receive(:get_vapp_by_name_and_vdc_name).with("test-vapp-1", "test-vdc-1").and_return(nil)
      @mock_fog_interface.should_receive(:template).with("org-1-catalog", "org-1-template").and_return({:href => '/vappTemplate-12345678-90ab-cdef-0123-4567890abcde'})
      Vcloud.logger.should_receive(:info)
      @mock_fog_interface.should_receive(:get_vapp).with('vapp-63d3be58-2d5c-477d-8410-267e7c3c4a02').and_return({:name => 'test-vapp-1'})
      Vcloud::Vm.stub(:new) { @mock_vm }
      Vcloud::FogServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

      actual_vapp = Vcloud::Vapp.new().provision config
      actual_vapp.should_not be_nil
      actual_vapp.name.should == 'test-vapp-1'
    end

    it "should log the error and move on if there is no template" do
      @mock_fog_interface.should_receive(:template).with("org-1-catalog", "org-1-template").and_return(nil)
      Vcloud::FogServiceInterface.should_receive(:new).and_return(@mock_fog_interface)

      Vcloud.logger.should_receive(:error).with("Could not provision vApp: Could not find template vApp.")
      Vcloud::Vapp.new.provision config
    end

  end

end
