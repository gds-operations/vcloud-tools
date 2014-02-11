require 'spec_helper'

describe Vcloud::Launch do
  context "storage profile", :take_too_long => true do
    before(:all) do
      @test_data = define_test_data
      @config_yaml = ErbHelper.convert_erb_template_to_yaml(@test_data, File.join(File.dirname(__FILE__), 'data/storage_profile.yaml.erb'))
      @fog_interface = Vcloud::Fog::ServiceInterface.new
      Vcloud::Launch.new.run(@config_yaml, {'dont-power-on' => true})

      @vapp_query_result_1 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_1], @test_data[:vdc_name_1])
      @vapp_id_1 = @vapp_query_result_1[:href].split('/').last
      @vapp_1 = @fog_interface.get_vapp @vapp_id_1
      @vm_1 = @vapp_1[:Children][:Vm].first

      @vapp_query_result_2 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_2], @test_data[:vdc_name_2])
      @vapp_id_2 = @vapp_query_result_2[:href].split('/').last
      @vapp_2 = @fog_interface.get_vapp @vapp_id_2
      @vm_2 = @vapp_2[:Children][:Vm].first

      @vapp_query_result_3 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_3], @test_data[:vdc_name_1])
      @vapp_id_3 = @vapp_query_result_3[:href].split('/').last
      @vapp_3 = @fog_interface.get_vapp @vapp_id_3
      @vm_3 = @vapp_3[:Children][:Vm].first

      @vapp_query_result_4 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_4], @test_data[:vdc_name_1])
      @vapp_id_4 = @vapp_query_result_4[:href].split('/').last
      @vapp_4 = @fog_interface.get_vapp @vapp_id_4
      @vm_4 = @vapp_4[:Children][:Vm].first
    end

    it "vdc 1 should have a storage profile without the href being specified" do
        @vm_1[:StorageProfile][:name].should == @test_data[:storage_profile]
    end

    it "vdc 1's storage profile should have the expected href" do
        @vm_1[:StorageProfile][:href].should == @test_data[:vdc_1_sp_href]
    end

    it "vdc 2 should have the same named storage profile as vdc 1" do
        @vm_2[:StorageProfile][:name].should == @test_data[:storage_profile]
    end

    it "the storage profile in vdc 2 should have a different href to the storage profile in vdc 1" do
        @vm_2[:StorageProfile][:href].should == @test_data[:vdc_2_sp_href]
    end

    it "when a storage profile is not specified, vm uses the default and continues" do
        @vm_3[:StorageProfile][:name].should == @test_data[:default_storage_profile_name]
        @vm_3[:StorageProfile][:href].should == @test_data[:default_storage_profile_href]
    end

    it "when a storage profile specified does not exist, vm uses the default" do
        @vm_4[:StorageProfile][:name].should == @test_data[:default_storage_profile_name]
        @vm_4[:StorageProfile][:href].should == @test_data[:default_storage_profile_href]
    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
        @fog_interface.delete_vapp(@vapp_id_1).should == true
        @fog_interface.delete_vapp(@vapp_id_2).should == true
        @fog_interface.delete_vapp(@vapp_id_3).should == true
        @fog_interface.delete_vapp(@vapp_id_4).should == true
      end
    end

  end

end

def define_test_data
  {
      vapp_name_1: "vdc-1-sp-#{Time.now.strftime('%s')}",
      vapp_name_2: "vdc-2-sp-#{Time.now.strftime('%s')}",
      vapp_name_3: "vdc-3-sp-#{Time.now.strftime('%s')}",
      vapp_name_4: "vdc-4-sp-#{Time.now.strftime('%s')}",
      vdc_name_1: ENV['VDC_NAME_1'],
      vdc_name_2: ENV['VDC_NAME_2'],
      catalog: ENV['VCLOUD_CATALOG_NAME'],
      vapp_template: ENV['VCLOUD_TEMPLATE_NAME'],
      storage_profile: ENV['VCLOUD_STORAGE_PROFILE_NAME'],
      vdc_1_sp_href: ENV['VDC_1_STORAGE_PROFILE_HREF'],
      vdc_2_sp_href: ENV['VDC_2_STORAGE_PROFILE_HREF'],
      default_storage_profile_name: ENV['DEFAULT_STORAGE_PROFILE_NAME'],
      default_storage_profile_href: ENV['DEFAULT_STORAGE_PROFILE_HREF'],
      nonsense_storage_profile: "nonsense-storage-profile-name",
      bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
  }
end
