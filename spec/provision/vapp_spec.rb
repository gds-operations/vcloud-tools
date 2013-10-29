require_relative '../spec_helper'

describe Provisioner::Vapp do
  before(:all) do
    @fog_interface = FogInterface.new(:test)
    TEST_VDC = 'GDS Networking API Testing (IL0-DEVTEST-BASIC)'
    template = @fog_interface.template('walker-ci', 'ubuntu-precise-image-2')
    @vapp_config = {
        'name' => "vapp-vcloud-tools-tests",
        'networks' => ['Default'],
        'hardware_config' => {
            'memory' => 4096,
            'cpu' => 1
        },
        'disks' => [{:size => '1024', :name => 'Hard disk 2'  }, {:size => '2048', :name => 'Hard disk 3'}],
        'ip_address' => '192.168.2.10'
    }
    @vapp = Provisioner::Vapp.new(@fog_interface).provision(@vapp_config, TEST_VDC, template)
  end

  context "provision vapp" do
    it "should create a vapp" do
      @vapp[:name].should == 'vapp-vcloud-tools-tests'
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

    it "should attach extra hard disks to vm" do
      vm = @vapp[:Children][:Vm].first
      disks = extract_disks(vm)
      disks.count.should == 3
      @vapp_config['disks'].each do |new_disk|
         disks.should include(new_disk)
      end
    end

    it "should configure the vm network interface" do
      vm = @vapp[:Children][:Vm].first
      vm_network_connection = vm[:NetworkConnectionSection][:NetworkConnection]
      vm_network_connection.should_not be_nil
      vm_network_connection[:network].should == 'Default'
      vm_network_connection[:NetworkConnectionIndex].should == '0'
      vm_network_connection[:IpAddress].should == '192.168.2.10'
      vm_network_connection[:IpAddressAllocationMode].should == 'MANUAL'

    end
  end

  after(:all) do
    @fog_interface.delete_vapp(@vapp[:href].split('/').last).should == true
  end

end

def extract_memory(vm)
  vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '4' }[:'rasd:VirtualQuantity']
end

def extract_cpu(vm)
  vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '3' }[:'rasd:VirtualQuantity']
end

def extract_disks vm
  vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].collect{|d|
    { :name => d[:"rasd:ElementName"] , :size => d[:"rasd:HostResource"][:ns12_capacity] } if d[:'rasd:ResourceType'] == '17'
  }.compact
end