require 'spec_helper'

describe Vcloud::ConfigLoader do

  before(:all) do
    @valid_config = valid_config
  end

  it "should create a valid hash when input is JSON" do
    input_file = 'spec/data/working.json'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config.should eq(actual_config)
  end


  it "should create a valid hash when input is YAML" do
    input_file = 'spec/data/working.yaml'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config.should eq(actual_config)
  end

  it "should create a valid hash when input is YAML with anchor defaults" do
    input_file = 'spec/data/working_with_defaults.yaml'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config.should eq(actual_config)
  end

  def valid_config
    {
      :vdcs=>[{:name=>"VDC_NAME"}],
      :vapps=>[{
        :name=>"vapp-vcloud-tools-tests",
        :vdc_name=>"VDC_NAME",
        :catalog=>"CATALOG_NAME",
        :catalog_item=>"CATALOG_ITEM",
        :vm=>{
          :hardware_config=>{:memory=>"4096", :cpu=>"2"},
          :extra_disks=>[{:size=>"8192"}],
          :network_connections=>[{
            :name=>"Default",
            :ip_address=>"192.168.2.10"
            },
            {
            :name=>"NetworkTest2",
            :ip_address=>"192.168.1.10"
          }],
          :bootstrap=>{
            :script_path=>"spec/data/basic_preamble_test.erb",
            :vars=>{:message=>"hello world"}
          },
          :metadata=>{}
        }
      }]
    }
  end

end
