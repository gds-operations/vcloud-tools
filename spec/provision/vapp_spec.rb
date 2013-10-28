require_relative '../spec_helper'

describe Provision::Vapp do
  before do
    @fog_interface = FogInterface.new(:test)
    TEST_VDC = "GDS Networking API Testing (IL0-DEVTEST-BASIC)"
    template = @fog_interface.template('walker-ci', 'ubuntu-precise-image-2')
    vapp_config = {'name' => 'vapp-111', 'networks' => ['Default'], 'hardware_config' => {'memory' => 4096, 'cpu' => 1}}
    @vapp = Provision::Vapp.new(@fog_interface).provision(vapp_config, TEST_VDC, template)
  end

  context "provision vapp" do
    it "should create a vapp" do
      @vapp[:name].should == 'vapp-111'
      @vapp[:"ovf:NetworkSection"][:"ovf:Network"][:ovf_name].should == "Default"
    end

    it "should create vm within vapp" do
      @vapp[:Children][:Vm].first.should_not be_nil
    end
  end

  context "customize vm" do
    it "change cpu for given vm" do
      vm = @vapp[:Children][:Vm].first

      extract_memory(vm).should == '4096'
      extract_cpu(vm).should == '1'
    end
  end

  after do
      @fog_interface.delete_vapp(@vapp[:href].split('/').last).should == true
  end

end

def extract_memory(vm)
  vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '4' }[:'rasd:VirtualQuantity']
end

def extract_cpu(vm)
  vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '3' }[:'rasd:VirtualQuantity']
end