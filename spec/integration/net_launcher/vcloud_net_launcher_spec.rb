require 'spec_helper'
require 'pp'
require 'erb'

describe Vcloud::NetLaunch, :take_too_long => true do

  context 'with minimum input setup' do

    it 'should create an isolated network' do
      test_data = default_test_data('isolated')
      @minimum_data_yaml = generate_data_file(test_data)

      Vcloud::NetLaunch.new.run(@minimum_data_yaml)

      @found_networks = find_network(test_data[:network_name])
      @found_networks.length.should == 1
      provisioned_network = @found_networks[0]
      provisioned_network[:gateway].should == test_data[:gateway]
      provisioned_network[:netmask].should == test_data[:netmask]
      provisioned_network[:isLinked].should == 'false'
    end

    it 'should create an nat routed network' do
      test_data = default_test_data('natRouted')
      test_data[:edgeGateway] =  ENV['VCLOUD_EDGE_GATEWAY']  #only needed for natRouted networks
      @minimum_data_yaml = generate_data_file(test_data)

      Vcloud::NetLaunch.new.run(@minimum_data_yaml)

      @found_networks = find_network(test_data[:network_name])

      @found_networks.length.should == 1
      provisioned_network = @found_networks[0]
      provisioned_network[:gateway].should == test_data[:gateway]
      provisioned_network[:netmask].should == test_data[:netmask]
      provisioned_network[:isLinked].should == 'true'
    end

    after(:each) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @minimum_data_yaml
        fog_interface = Vcloud::Fog::ServiceInterface.new
        provisioned_network_id = @found_networks[0][:href].split('/').last
        fog_interface.delete_network(provisioned_network_id).should == true
      end
    end

  end

  def default_test_data(type)
    {
      network_name: "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
      vdc_name: ENV['VCLOUD_VDC_NAME'],
      fence_mode: type,
      netmask: '255.255.255.0',
      gateway: '192.0.2.1',
    }
  end

  def find_network(network_name)
    query = Vcloud::QueryRunner.new()
    query.run('orgNetwork', :filter => "name==#{network_name}")
  end

  def generate_data_file(test_data)
    minimum_data_erb = File.join(File.dirname(__FILE__), 'data/minimum_data_setup.yaml.erb')
    ErbHelper.convert_erb_template_to_yaml(test_data, minimum_data_erb)
  end

end
