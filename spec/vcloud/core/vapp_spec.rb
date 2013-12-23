require 'spec_helper'

module Vcloud
  module Core
    describe Vapp do
      before(:each) do
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
      end

      context "attributes" do
        before(:each) {
          attributes = {
              :name => 'Webserver vapp-1',
              :href => 'https://api.vcd.portal.skyscapecloud.com/api/vApp/vapp-7647f3ab-ede5-4d07-bad5-4e2235800ef3',
              :Link => [{
                            :rel => 'up',
                            :type => 'application/vnd.vmware.vcloud.vdc+xml',
                            :href => 'https://api.vcloud-director.example.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237'
                        }],
              :Children => {:Vm => [{:href => '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237'}]}
          }
          @vapp = Vapp.new(attributes)
        }
        it { @vapp.should respond_to(:vcloud_attributes) }
        it { @vapp.name.should == 'Webserver vapp-1' }

        context "id" do
          it "should extract id correctly" do
            @vapp.id.should == 'vapp-7647f3ab-ede5-4d07-bad5-4e2235800ef3'
          end

          it "should raise error if id is not in correct format" do
            @vapp = Vapp.new({:href => 'https://api.vcd.portal.skyscapecloud.com/api/vApp/7647f3ab-ede5-4d07-bad5-4e2235800ef3' })
            lambda { @vapp.id }.should raise_error("vapp id : 7647f3ab-ede5-4d07-bad5-4e2235800ef3 is not in correct format" )
          end
        end
        context "vapp should have parent vdc" do
          it "should load parent vdc id from fog attributes" do
            @vapp.vdc_id.should == '074aea1e-a5e9-4dd1-a028-40db8c98d237'
          end

          it "should raise error if vapp without parent vdc found" do
            vapp_without_vdc = Vcloud::Core::Vapp.new({:Link => []})
            lambda { vapp_without_vdc.vdc_id }.should raise_error('a vapp without parent vdc found')
          end
        end

        it "should return vms" do
          @vapp.fog_vms.count.should == 1
          @vapp.fog_vms.first[:href].should == '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237'
        end
      end

      context "power on" do
        context "successful power on" do
          before(:each) do
            @fog_vapp_body = {
                :name => "Webserver vapp-1",
                :href => "https://api.vcloud-director.example.com/api/vApp/vapp-63d3be58-2d5c-477d-8410-267e7c3c4a02",
                :Link => [{
                              :rel => "up",
                              :type => "application/vnd.vmware.vcloud.vdc+xml",
                              :href => "https://api.vcloud-director.example.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237"
                          }]
            }
          end

          it "should power on a vapp that is not powered on" do
            vapp = Vapp.new(@fog_vapp_body)
            @mock_fog_interface.should_receive(:get_vapp).twice().and_return({:status => 8})
            @mock_fog_interface.should_receive(:power_on_vapp).with(vapp.id)
            state = vapp.power_on
            expect(state) == true
          end

          it "should not power on a vapp that is already powered on, but should return true" do
            vapp = Vapp.new(@fog_vapp_body)
            @mock_fog_interface.should_receive(:get_vapp).and_return({:status => 4})
            @mock_fog_interface.should_not_receive(:power_on_vapp)
            state = vapp.power_on
            expect(state) == true
          end
        end

      end

      context "#get_by_name_and_vdc_name" do

        it "should return nil if fog returns nil" do
          StubFogInterface.any_instance.stub(:get_vapp_by_name_and_vdc_name)
            .with('vapp_name', 'vdc_name').and_return(nil)
          Vapp.get_by_name_and_vdc_name('vapp_name', 'vdc_name').should == nil

        end

        it "should return vapp instance if found" do

          vcloud_attr_vapp = {:id => 1}
          StubFogInterface.any_instance.stub(:get_vapp_by_name_and_vdc_name)
          .with('vapp_name', 'vdc_name').and_return(vcloud_attr_vapp)

          Vapp.get_by_name_and_vdc_name('vapp_name', 'vdc_name').class.should == Core::Vapp

        end
      end

    end
  end
end

