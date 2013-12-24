require 'spec_helper'
require 'pp'

describe Vcloud::Core::OrgVdcNetwork do

  context "natRouted network" do

    before(:all) do
      test_data = define_test_data
      @config = {
        :name => test_data[:name],
        :description => "Integration Test network #{@name}",
        :vdc_name => test_data[:vdc_name],
        :fence_mode => 'natRouted',
        :edge_gateway => test_data[:edge_gateway_name],
        :gateway => '10.88.11.1',
        :netmask => '255.255.255.0',
        :dns1 => '8.8.8.8',
        :dns2 => '8.8.4.4',
        :ip_ranges => [
            { :start_address => '10.88.11.100',
              :end_address   => '10.88.11.150' },
            { :start_address => '10.88.11.200',
              :end_address   => '10.88.11.250' },
          ],
      }
      @net = Vcloud::Core::OrgVdcNetwork.provision(@config)
    end

    it 'should be an OrgVdcNetwork' do
      expect(@net.class).to be(Vcloud::Core::OrgVdcNetwork)
    end

    it 'should have an id' do
      expect(@net.id).to match(/^[0-9a-f-]+$/)
    end

    it 'should have a name' do
      expect(@net.name) == @config[:name]
    end

    it 'should have a :gateway attribute' do
      expect(@net.vcloud_attributes[:gateway]) == @config[:gateway]
    end

    it 'should have a :netmask attribute' do
      expect(@net.vcloud_attributes[:gateway]) == @config[:netmask]
    end

    it 'should have a :dns1 attribute' do
      expect(@net.vcloud_attributes[:dns1]) == @config[:dns1]
    end

    it 'should have a :dns2 attribute' do
      expect(@net.vcloud_attributes[:dns2]) == @config[:dns2]
    end

    it 'should have an :ip_ranges attribute' do
      expect(@net.vcloud_attributes[:ip_ranges]) == [
        {:start_address=>"10.88.11.200", :end_address=>"10.88.11.250"},
        {:start_address=>"10.88.11.100", :end_address=>"10.88.11.150"}
      ]
    end

    after(:all) do
      pp @net.vcloud_attributes
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_ORG_VDC_NETWORK']
        Vcloud::Fog::ServiceInterface.new.delete_network(@net.id) if @net
      end
    end

  end

  context "isolated network" do

    before(:all) do
      test_data = define_test_data
      @config = {
        :name => test_data[:name],
        :description => "Integration Test network #{@name}",
        :vdc_name => test_data[:vdc_name],
        :fence_mode => 'isolated',
        :gateway => '10.88.11.1',
        :netmask => '255.255.255.0',
        :dns1 => '8.8.8.8',
        :dns2 => '8.8.4.4',
        :ip_ranges => [
            { :start_address => '10.88.11.100',
              :end_address   => '10.88.11.150' },
            { :start_address => '10.88.11.200',
              :end_address   => '10.88.11.250' },
          ],
      }
      @net = Vcloud::Core::OrgVdcNetwork.provision(@config)
    end

    it 'should be an OrgVdcNetwork' do
      expect(@net.class).to be(Vcloud::Core::OrgVdcNetwork)
    end

    it 'should have an id' do
      expect(@net.id).to match(/^[0-9a-f-]+$/)
    end

    it 'should have a name' do
      expect(@net.name) == @config[:name]
    end

    it 'should have a :gateway attribute' do
      expect(@net.vcloud_attributes[:gateway]) == @config[:gateway]
    end

    it 'should have a :netmask attribute' do
      expect(@net.vcloud_attributes[:gateway]) == @config[:netmask]
    end

    it 'should have a :dns1 attribute' do
      expect(@net.vcloud_attributes[:dns1]) == @config[:dns1]
    end

    it 'should have a :dns2 attribute' do
      expect(@net.vcloud_attributes[:dns2]) == @config[:dns2]
    end

    it 'should have an :ip_ranges attribute' do
      expect(@net.vcloud_attributes[:ip_ranges]) == [
        {:start_address=>"10.88.11.200", :end_address=>"10.88.11.250"},
        {:start_address=>"10.88.11.100", :end_address=>"10.88.11.150"}
      ]
    end

    after(:all) do
      pp @net.vcloud_attributes
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_ORG_VDC_NETWORK']
        Vcloud::Fog::ServiceInterface.new.delete_network(@net.id) if @net
      end
    end

  end

end

def define_test_data
  [ 'VCLOUD_VDC_NAME', 'VCLOUD_EDGE_GATEWAY' ].each do |n|
    raise "Need #{n} set" unless ENV[n]
  end
  {
    :name => "orgVdcNetwork-vcloud-tools-tests #{Time.now.strftime('%s')}",
    :vdc_name => ENV['VCLOUD_VDC_NAME'],
    :edge_gateway_name => ENV['VCLOUD_EDGE_GATEWAY'],
  }
end
