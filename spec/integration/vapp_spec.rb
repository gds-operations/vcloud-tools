require 'spec_helper'
require 'pp'

describe Vcloud::Vapp do
  before(:all) do
    @fog_interface = Vcloud::FogServiceInterface.new
    TEST_VDC      = ENV['VCLOUD_TEST_VDC']      || 'Test vDC'
    TEST_CATALOG  = ENV['VCLOUD_TEST_CATALOG']  || 'test-catalog'
    TEST_TEMPLATE = ENV['VCLOUD_TEST_TEMPLATE'] || 'test-template'
    TEST_NETWORK1 = ENV['VCLOUD_TEST_NETWORK1'] || 'Default'
    TEST_NETWORK2 = ENV['VCLOUD_TEST_NETWORK2'] || 'NetworkTest2'
    TEST_NETWORK1_IP = ENV['VCLOUD_TEST_NETWORK1_IP'] || '192.168.2.10'
    TEST_NETWORK2_IP = ENV['VCLOUD_TEST_NETWORK2_IP'] || '192.168.1.10'
    TEST_STORAGE_PROFILE = ENV['VCLOUD_TEST_STORAGE_PROFILE'] || 'TestStorageProfile'
    TEST_STORAGE_PROFILE_HREF = ENV['VCLOUD_TEST_STORAGE_PROFILE_HREF'] || 'https://vcloud.examples.net/api/vdcStorageProfile/1'

    template = @fog_interface.template(TEST_CATALOG, TEST_TEMPLATE)
    script_path = File.join(File.dirname(__FILE__), "../data/basic_preamble_test.erb")

    # NB: be careful with DateTime.now et al, as object has nanoseconds which
    # are lost in serialization
    comparison_date = DateTime.parse('2013-10-23 15:34:00 +0000')
    @vapp_config = {
        :name => "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
        :vdc_name => "#{TEST_VDC}",
        :catalog  => "#{TEST_CATALOG}",
        :catalog_item  => "#{TEST_TEMPLATE}",
        :vm => {
          :hardware_config => {
              :memory => 4096,
              :cpu => 2
          },
          :metadata => {
            :is_integer => 1024,
            :is_string  => 'Hello World',
            :is_datetime => comparison_date,
            :is_true => true,
            :is_false => false,
            :integration_test_vm => true,
          },
          :extra_disks => [
            {:size => '1024', :name => 'Hard disk 2'},
            {:size => '2048', :name => 'Hard disk 3'}
          ],
          :network_connections => [
            {:name => "#{TEST_NETWORK1}", :ip_address => "#{TEST_NETWORK1_IP}"},
            {:name => "#{TEST_NETWORK2}", :ip_address => "#{TEST_NETWORK2_IP}"},
          ],
          :bootstrap => {
            :script_path => script_path,
            :vars => {
              :message => 'hello world'
            },
          },
          :storage_profile => {
            :name => TEST_STORAGE_PROFILE,
            :href => TEST_STORAGE_PROFILE_HREF
          }
        },
    }

    @vapp = Vcloud::Vapp.new.provision(@vapp_config).vcloud_attributes
    @vapp_id = @vapp[:href].split('/').last
    @vm = @vapp[:Children][:Vm].first
    @vm_id = @vm[:href].split('/').last

    @vapp_metadata = @fog_interface.get_vapp_metadata_hash(@vm_id)
  end

  context 'provision vapp' do
    it 'should create a vapp' do
      @vapp[:name].should == @vapp_config[:name]
      @vapp[:'ovf:NetworkSection'][:'ovf:Network'].count.should == 2
      vapp_networks = @vapp[:'ovf:NetworkSection'][:'ovf:Network'].collect {|connection| connection[:ovf_name]}
      vapp_networks.should =~ [TEST_NETWORK1, TEST_NETWORK2]
    end

    it "should create vm within vapp" do
      @vm.should_not be_nil
    end

  end

  context "customize vm" do
    it "change cpu for given vm" do
      extract_memory(@vm).should == @vapp_config[:vm][:hardware_config][:memory].to_s
      extract_cpu(@vm).should == @vapp_config[:vm][:hardware_config][:cpu].to_s
    end

    it "should have added the right number of metadata values" do
      @vapp_metadata.count.should == @vapp_config[:vm][:metadata].count
    end

    it "the metadata should be equivalent to our input" do
      @vapp_metadata.each do |k, v|
        @vapp_config[:vm][:metadata][k].should == v
      end
    end

    it "should attach extra hard disks to vm" do
      disks = extract_disks(@vm)
      disks.count.should == 3
      @vapp_config[:vm][:extra_disks].each do |new_disk|
         disks.should include(new_disk)
      end
    end

    it "should configure the vm network interface" do
      vm_network_connection = @vm[:NetworkConnectionSection][:NetworkConnection]
      vm_network_connection.should_not be_nil
      vm_network_connection.count.should == 2


      primary_nic = vm_network_connection.detect{|connection| connection[:network] == TEST_NETWORK1}
      primary_nic[:network].should == TEST_NETWORK1
      primary_nic[:NetworkConnectionIndex].should == @vm[:NetworkConnectionSection][:PrimaryNetworkConnectionIndex]
      primary_nic[:IpAddress].should == TEST_NETWORK1_IP
      primary_nic[:IpAddressAllocationMode].should == 'MANUAL'

      second_nic = vm_network_connection.detect{|connection| connection[:network] == TEST_NETWORK2}
      second_nic[:network].should == TEST_NETWORK2
      second_nic[:NetworkConnectionIndex].should == '1'
      second_nic[:IpAddress].should == TEST_NETWORK2_IP
      second_nic[:IpAddressAllocationMode].should == 'MANUAL'

    end

    it 'should assign guest customization script to the VM' do
      @vm[:GuestCustomizationSection][:CustomizationScript].should =~ /message: hello world/
      @vm[:GuestCustomizationSection][:ComputerName].should == @vapp_config[:name]
    end

    it "should assign storage profile to the VM" do
      @vm[:StorageProfile][:name].should == TEST_STORAGE_PROFILE
      @vm[:StorageProfile][:href].should == TEST_STORAGE_PROFILE_HREF
    end

  end

  after(:all) do
    unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
      @fog_interface.delete_vapp(@vapp_id).should == true
    end
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
