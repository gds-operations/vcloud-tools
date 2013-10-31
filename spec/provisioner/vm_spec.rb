require_relative '../spec_helper'

describe Provisioner::Vm do

  context "configure vm network connections" do
    it "should configure single nic" do
      fog_interface = double(:fog_interface)
      network_config = [{'name' => 'Default', 'ip_address' => '192.168.1.1'}]
      mock_vm = {:name => 'vm-1', :href => 'vm-href/1'}
      fog_interface.should_receive(:put_network_connection_system_section_vapp).with('1', {
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

      Provisioner::Vm.new(fog_interface, mock_vm, 'vapp-1').configure_network_interfaces(network_config)
    end

    it "should configure multiple nics" do
      fog_interface = double(:fog_interface)
      network_config = [{'name' => 'Default', 'ip_address' => '192.168.1.1'}, {'name' => 'Monitoring', 'ip_address' => '192.168.2.1'}]
      mock_vm = {:name => 'vm-1', :href => 'vm-href/1'}

      fog_interface.should_receive(:put_network_connection_system_section_vapp).with('1', {
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
      Provisioner::Vm.new(fog_interface, mock_vm, 'vapp-1').configure_network_interfaces(network_config)
    end

    it "should configure no nics" do
      fog_interface = double(:fog_interface)
      network_config = nil
      mock_vm = {:name => 'vm-1', :href => 'vm-href/1'}

      fog_interface.should_not_receive(:put_network_connection_system_section_vapp)
      Provisioner::Vm.new(fog_interface, mock_vm, 'vapp-1').configure_network_interfaces(network_config)
    end
  end

end
