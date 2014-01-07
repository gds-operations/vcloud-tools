require 'spec_helper'
require 'pp'
require 'erb'
require 'ostruct'

describe Vcloud::Launch do
  context "with minimum input setup" do
    it "should provision vapp with single vm" do
      test_data_1 = define_test_data
      minimum_data_erb = File.join(File.dirname(__FILE__), 'data/minimum_data_setup.yaml.erb')
      @minimum_data_yaml = generate_input_yaml_config(test_data_1, minimum_data_erb)
      @fog_interface = Vcloud::Fog::ServiceInterface.new

      Vcloud::Launch.new.run(@minimum_data_yaml, {:no_power_on => true})

      vapp_query_result = @fog_interface.get_vapp_by_name_and_vdc_name(test_data_1[:vapp_name], test_data_1[:vdc_name])
      @provisioned_vapp_id = vapp_query_result[:href].split('/').last
      provisioned_vapp = @fog_interface.get_vapp @provisioned_vapp_id

      provisioned_vapp.should_not be_nil
      provisioned_vapp[:name].should == test_data_1[:vapp_name]
      provisioned_vapp[:Children][:Vm].count.should == 1
    end

    after(:each) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @minimum_data_yaml
        @fog_interface.delete_vapp(@provisioned_vapp_id).should == true
      end
    end
  end

  context "happy path" do
    before(:all) do
      @test_data = define_test_data
      @config_yaml = generate_input_yaml_config(@test_data, File.join(File.dirname(__FILE__), 'data/happy_path.yaml.erb'))
      @fog_interface = Vcloud::Fog::ServiceInterface.new
      Vcloud::Launch.new.run(@config_yaml, {:no_power_on => true})

      @vapp_query_result = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name], @test_data[:vdc_name])
      @vapp_id = @vapp_query_result[:href].split('/').last

      @vapp = @fog_interface.get_vapp @vapp_id
      @vm = @vapp[:Children][:Vm].first
      @vm_id = @vm[:href].split('/').last

      @vm_metadata = Vcloud::Core::Vm.get_metadata @vm_id
    end

    context 'provision vapp' do
      it 'should create a vapp' do
        @vapp[:name].should == @test_data[:vapp_name]
        @vapp[:'ovf:NetworkSection'][:'ovf:Network'].count.should == 2
        vapp_networks = @vapp[:'ovf:NetworkSection'][:'ovf:Network'].collect { |connection| connection[:ovf_name] }
        vapp_networks.should =~ [@test_data[:network1], @test_data[:network2]]
      end

      it "should create vm within vapp" do
        @vm.should_not be_nil
      end

    end

    context "customize vm" do
      it "change cpu for given vm" do
        extract_memory(@vm).should == '4096'
        extract_cpu(@vm).should == '2'
      end

      it "should have added the right number of metadata values" do
        @vm_metadata.count.should == 6
      end

      it "the metadata should be equivalent to our input" do
        @vm_metadata[:is_true].should == true
        @vm_metadata[:is_integer].should == -999
        @vm_metadata[:is_string].should == 'Hello World'
      end

      it "should attach extra hard disks to vm" do
        disks = extract_disks(@vm)
        disks.count.should == 3
        [{:name => 'Hard disk 2', :size => '1024'}, {:name => 'Hard disk 3', :size => '2048'}].each do |new_disk|
          disks.should include(new_disk)
        end
      end

      it "should configure the vm network interface" do
        vm_network_connection = @vm[:NetworkConnectionSection][:NetworkConnection]
        vm_network_connection.should_not be_nil
        vm_network_connection.count.should == 2


        primary_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network1] }
        primary_nic[:network].should == @test_data[:network1]
        primary_nic[:NetworkConnectionIndex].should == @vm[:NetworkConnectionSection][:PrimaryNetworkConnectionIndex]
        primary_nic[:IpAddress].should == @test_data[:network1_ip]
        primary_nic[:IpAddressAllocationMode].should == 'MANUAL'

        second_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network2] }
        second_nic[:network].should == @test_data[:network2]
        second_nic[:NetworkConnectionIndex].should == '1'
        second_nic[:IpAddress].should == @test_data[:network2_ip]
        second_nic[:IpAddressAllocationMode].should == 'MANUAL'

      end

      it 'should assign guest customization script to the VM' do
        @vm[:GuestCustomizationSection][:CustomizationScript].should =~ /message: hello world/
        @vm[:GuestCustomizationSection][:ComputerName].should == @test_data[:vapp_name]
      end

      it "should assign storage profile to the VM" do
        @vm[:StorageProfile][:name].should == @test_data[:storage_profile]
      end

    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
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

  def extract_disks(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].collect { |d|
      {:name => d[:"rasd:ElementName"], :size => d[:"rasd:HostResource"][:ns12_capacity]} if d[:'rasd:ResourceType'] == '17'
    }.compact
  end


  def generate_input_yaml_config test_namespace, input_erb_config
    input_erb_config = input_erb_config
    e = ERB.new(File.open(input_erb_config).read)
    output_yaml_config = File.join(File.dirname(input_erb_config), "output_#{Time.now.strftime('%s')}.yaml")
    File.open(output_yaml_config, 'w') { |f|
      f.write e.result(OpenStruct.new(test_namespace).instance_eval { binding })
    }
    output_yaml_config
  end

  def define_test_data
    {
        vapp_name: "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
        vdc_name: ENV['VCLOUD_VDC_NAME'],
        catalog: ENV['VCLOUD_CATALOG_NAME'],
        vapp_template: ENV['VCLOUD_TEMPLATE_NAME'],
        network1: ENV['VCLOUD_NETWORK1_NAME'],
        network2: ENV['VCLOUD_NETWORK2_NAME'],
        network1_ip: ENV['VCLOUD_NETWORK1_IP'],
        network2_ip: ENV['VCLOUD_NETWORK2_IP'],
        storage_profile: ENV['VCLOUD_STORAGE_PROFILE_NAME'],
        storage_profile_href: ENV['VCLOUD_TEST_STORAGE_PROFILE_HREF'], # https://vcloud.examples.net/api/vdcStorageProfile/1
        bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
        date_metadata: DateTime.parse('2013-10-23 15:34:00 +0000')
    }
  end

  def define_test_data
    {
        vapp_name: "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
        vdc_name: ENV['VCLOUD_VDC_NAME'],
        catalog: ENV['VCLOUD_CATALOG_NAME'],
        vapp_template: ENV['VCLOUD_TEMPLATE_NAME'],
        network1: ENV['VCLOUD_NETWORK1_NAME'],
        network2: ENV['VCLOUD_NETWORK2_NAME'],
        network1_ip: ENV['VCLOUD_NETWORK1_IP'],
        network2_ip: ENV['VCLOUD_NETWORK2_IP'],
        storage_profile: ENV['VCLOUD_STORAGE_PROFILE_NAME'],
        bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
        date_metadata: DateTime.parse('2013-10-23 15:34:00 +0000')
    }
  end
end
