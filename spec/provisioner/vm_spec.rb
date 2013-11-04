require_relative '../spec_helper'

module Provisioner

  describe Provisioner::Vm do

    before(:each) do
      @vm_id   = 'vm-1234'
      @vapp_id = 'vapp-4321'
      @vapp_name = 'test-vm-1'
      @data_dir = File.join(File.dirname(__FILE__), "../data")
      @mock_vm_memory_size = 1024
      @mock_metadata = {
        :foo => "bar",
        :false_thing => false,
        :true_thing => true,
        :number => 53,
        :zero => 0,
      }
      @mock_vm_cpu_count = 1
      @fog_interface = double(:fog_interface)
      @mock_vapp     = double(:vapp)
      @mock_vapp.stub(:name).and_return(@vapp_name)
      @mock_vapp.stub(:id).and_return(@vapp_id)
      @mock_vm = {
        :name => "#{@vapp_name}",
        :href => "vm-href/#{@vm_id}",
        :'ovf:VirtualHardwareSection' => {
          :'ovf:Item' => [
            {
              :'rasd:ResourceType'    => '4',
              :'rasd:VirtualQuantity' => "#{@mock_vm_memory_size}",
            },
            {
              :'rasd:ResourceType' => '3',
              :'rasd:VirtualQuantity' => "#{@mock_vm_cpu_count}",
            }
          ]
        }
      }
      @vm = Provisioner::Vm.new(@fog_interface, @mock_vm, @mock_vapp)

    end

    describe '#update_memory_size_in_mb' do
      context "update memory in VM" do
        it "should not allow memory size < 64MB" do
          @fog_interface.should_not_receive(:put_memory)
          @vm.update_memory_size_in_mb(63)
        end
        it "should not update memory if is size has not changed" do
          @fog_interface.should_not_receive(:put_memory)
          @vm.update_memory_size_in_mb(@mock_vm_memory_size)
        end
        it "should gracefully handle a nil memory size" do
          @fog_interface.should_not_receive(:put_memory)
          @vm.update_memory_size_in_mb(nil)
        end
        it "should set memory size 64MB" do
          @fog_interface.should_receive(:put_memory).with(@vm_id, 64)
          @vm.update_memory_size_in_mb(64)
        end
        it "should set memory size 4096MB" do
          @fog_interface.should_receive(:put_memory).with(@vm_id, 4096)
          @vm.update_memory_size_in_mb(4096)
        end
      end
    end

    describe '#update_cpu_count' do
      context "update the number of cpus in vm" do
        it "should gracefully handle nil cpu count" do
          @fog_interface.should_not_receive(:put_cpu)
          @vm.update_cpu_count(nil)
        end
        it "should not update cpu if is count has not changed" do
          @fog_interface.should_not_receive(:put_cpu)
          @vm.update_cpu_count(@mock_vm_cpu_count)
        end
        it "should not allow a zero cpu count" do
          @fog_interface.should_not_receive(:put_cpu)
          @vm.update_cpu_count(0)
        end
        it "should update cpu count in input is ok" do
          @fog_interface.should_receive(:put_cpu).with(@vm_id, 2)
          @vm.update_cpu_count(2)
        end
      end
    end

    describe '#generate_preamble' do
      context "configure vm network connections" do
        it "should interpolate facts hash into template" do
          facts = { :message => 'hello world' }
          erbfile = "#{@data_dir}/basic_preamble_test.erb"
          expected_output = File.read("#{erbfile}.OUT")
          @vm.generate_preamble(erbfile, facts).should == expected_output
        end
        it "should minify script if >=2048 bytes" do
          facts = { :message => 'hello world' }
          erbfile = "#{@data_dir}/unminified_large_script.sh.erb"
          expected_output = File.read("#{erbfile}.OUT")
          @vm.generate_preamble(erbfile, facts).should == expected_output
        end
      end
    end

    describe '#update_metadata' do
      context "it should update the key+value vm+vapp metadata" do
        it "should handle empty metadata hash" do
          @fog_interface.should_not_receive(:put_vapp_metadata_value)
          @vm.update_metadata(nil)
        end
        it "should handle metadata of multiple types" do
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vm_id, :foo, 'bar')
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vm_id, :false_thing, false)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vm_id, :true_thing, true)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vm_id, :number, 53)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vm_id, :zero, 0)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vapp_id, :foo, 'bar')
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vapp_id, :false_thing, false)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vapp_id, :true_thing, true)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vapp_id, :number, 53)
          @fog_interface.should_receive(:put_vapp_metadata_value).with(@vapp_id, :zero, 0)
          @vm.update_metadata(@mock_metadata)
        end
      end
    end

    describe '#configure_network_interfaces' do

      context "configure vm network connections" do

        it "should configure single nic" do
          network_config = [{:name => 'Default', :ip_address => '192.168.1.1'}]
          @fog_interface.should_receive(:put_network_connection_system_section_vapp).with(@vm_id, {
              :PrimaryNetworkConnectionIndex => 0,
              :NetworkConnection => [
                  {
                      :network => 'Default',
                      :needsCustomization => true,
                      :NetworkConnectionIndex => 0,
                      :IsConnected => true,
                      :IpAddress => "192.168.1.1",
                      :IpAddressAllocationMode => "MANUAL"
                  }
              ]})
          @vm.configure_network_interfaces(network_config)
        end

        it "should configure multiple nics" do
          network_config = [
            {:name => 'Default', :ip_address => '192.168.1.1'}, 
            {:name => 'Monitoring', :ip_address => '192.168.2.1'}
          ]

          @fog_interface.should_receive(:put_network_connection_system_section_vapp).with(@vm_id, {
              :PrimaryNetworkConnectionIndex => 0,
              :NetworkConnection => [
                  {
                      :network => 'Default',
                      :needsCustomization => true,
                      :NetworkConnectionIndex => 0,
                      :IsConnected => true,
                      :IpAddress => "192.168.1.1",
                      :IpAddressAllocationMode => "MANUAL"
                  },
                  {
                      :network => 'Monitoring',
                      :needsCustomization => true,
                      :NetworkConnectionIndex => 1,
                      :IsConnected => true,
                      :IpAddress => "192.168.2.1",
                      :IpAddressAllocationMode => "MANUAL"
                  },
              ]})
          @vm.configure_network_interfaces(network_config)
        end

        it "should configure no nics" do
          network_config = nil
          @fog_interface.should_not_receive(:put_network_connection_system_section_vapp)
          @vm.configure_network_interfaces(network_config)
        end

      end

    end

  end

end
