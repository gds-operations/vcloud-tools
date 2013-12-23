require 'spec_helper'

module Vcloud
  module Core
    describe Vapp do
      before(:each) do
        @vapp_id = 'vapp-12345678-1234-1234-1234-000000111111'
        @mock_fog_interface = StubFogInterface.new
        Vcloud::Fog::ServiceInterface.stub(:new).and_return(@mock_fog_interface)
      end

      context "Class public interface" do
        it { Vapp.should respond_to(:instantiate) }
        it { Vapp.should respond_to(:get_by_name) }
        it { Vapp.should respond_to(:get_metadata) }
      end

      context "Instance public interface" do
        subject { Vapp.new(@vapp_id) }
        it { should respond_to(:id) }
        it { should respond_to(:vcloud_attributes) }
        it { should respond_to(:name) }
        it { should respond_to(:href) }
        it { should respond_to(:vdc_id) }
        it { should respond_to(:fog_vms) }
        it { should respond_to(:networks) }
        it { should respond_to(:power_on) }
      end

      context "#initialize" do

        it "should be constructable from just an id reference" do
          obj = Vapp.new(@vapp_id)
          expect(obj.class).to be(Vcloud::Core::Vapp)
        end

        it "should store the id specified" do
          obj = Vapp.new(@vapp_id)
          expect(obj.id) == @vapp_id
        end

        it "should raise error if id is not in correct format" do
          bogus_id = '12314124-ede5-4d07-bad5-000000111111'
          expect{ Vapp.new(bogus_id) }.to raise_error("vapp id : #{bogus_id} is not in correct format" )
        end

      end

      context "#get_by_name" do

        it "should return a Vapp object if name exists" do
          q_results = [
            { :name => 'vapp-test-1', :href => @vapp_id }
          ]
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          obj = Vapp.get_by_name('vapp-test-1')
          expect(obj.class).to be(Vcloud::Core::Vapp)
        end

        it "should raise an error if no vApp with that name exists" do
          q_results = [ ]
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          expect{ Vapp.get_by_name('vapp-test-1') }.to raise_exception(RuntimeError)
        end

        it "should raise an error if multiple vApps with that name exists (NB: prescribes unique vApp names!)" do
          q_results = [
            { :name => 'vapp-test-1', :href => @vapp_id },
            { :name => 'vapp-test-1', :href => '/bogus' },
          ]
          Vcloud::Query.any_instance.stub(:get_all_results).and_return(q_results)
          expect{ Vapp.get_by_name('vapp-test-1') }.to raise_exception(RuntimeError)
        end

      end

      context "attributes" do
        before(:each) {
          @stub_attrs = {
              :name => 'Webserver vapp-1',
              :href => "https://api.vcd.portal.skyscapecloud.com/api/vApp/#{@vapp_id}",
              :Link => [{
                            :rel => 'up',
                            :type => 'application/vnd.vmware.vcloud.vdc+xml',
                            :href => 'https://api.vcloud-director.example.com/api/vdc/074aea1e-a5e9-4dd1-a028-40db8c98d237'
                        }],
              :Children => {:Vm => [{:href => '/vm-123aea1e-a5e9-4dd1-a028-40db8c98d237'}]}
          }
          StubFogInterface.any_instance.stub(:get_vapp).and_return(@stub_attrs)
          @vapp = Vapp.new(@vapp_id)
        }
        it { @vapp.name.should == 'Webserver vapp-1' }

        context "id" do
          it "should extract id correctly" do
            @vapp.id.should == @vapp_id
          end
        end

        context "vapp should have parent vdc" do
          it "should load parent vdc id from fog attributes" do
            @vapp.vdc_id.should == '074aea1e-a5e9-4dd1-a028-40db8c98d237'
          end

          it "should raise error if vapp without parent vdc found" do
            @stub_attrs[:Link] = []
            lambda { @vapp.vdc_id }.should raise_error('a vapp without parent vdc found')
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
            vapp = Vapp.new(@vapp_id)
            @mock_fog_interface.should_receive(:get_vapp).twice().and_return({:status => 8})
            @mock_fog_interface.should_receive(:power_on_vapp).with(vapp.id)
            state = vapp.power_on
            expect(state) == true
          end

          it "should not power on a vapp that is already powered on, but should return true" do
            vapp = Vapp.new(@vapp_id)
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
          vcloud_attr_vapp = { :href => "/#{@vapp_id}" }
          StubFogInterface.any_instance.stub(:get_vapp_by_name_and_vdc_name)
            .with('vapp_name', 'vdc_name').and_return(vcloud_attr_vapp)
          Vapp.get_by_name_and_vdc_name('vapp_name', 'vdc_name').class.should == Core::Vapp
        end

      end

    end
  end
end

