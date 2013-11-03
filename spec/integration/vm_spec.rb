require_relative '../spec_helper'

describe Provisioner::Vm do

  context 'vm guest customization' do

    it 'should assign guest customization script to a VM' do
      fog_interface = FogInterface.new(:test)
      script_path = File.join(File.dirname(__FILE__), "../data/default_preamble.sh.erb")
      p script_path
      facts = { :message => 'hello world' }

      vm = Provisioner::Vm.new(fog_interface, { :href => '/vm-dee1464a-19b8-4996-b709-e33b467cfe23' }, {})

      vm.configure_guest_customization_section 'test-vm', script_path, facts
      vm[:GuestCustomizationSection][:CustomizationScript].should =~ 'message: hello world'  
      vm[:GuestCustomizationSection][:ComputerName].should == 'test-vm'
    end

  end

end
