require 'spec_helper'

describe Vcloud::ConfigLoader do

  before(:all) do
    @valid_config = valid_config
  end

  it "should create a valid hash when input is JSON" do
    input_file = 'spec/vcloud/data/working.json'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config.should eq(actual_config)
  end


  it "should create a valid hash when input is YAML" do
    input_file = 'spec/vcloud/data/working.yaml'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config.should eq(actual_config)
  end

  it "should create a valid hash when input is YAML with anchor defaults" do
    input_file = 'spec/vcloud/data/working_with_defaults.yaml'
    loader = Vcloud::ConfigLoader.new
    actual_config = loader.load_config(input_file)
    valid_config['vapps'].should eq(actual_config['vapps'])
  end

  context "parsing example configurations" do
    examples_dir = File.join(
      File.dirname(__FILE__),
      '..', '..', 'examples'
    )
    Dir["#{examples_dir}/**/*.yaml"].each do |input_file|
      it "should parse example config #{File.basename(input_file)}" do
        loader = Vcloud::ConfigLoader.new
        actual_config = loader.load_config(input_file)
        expect(actual_config).to be_true
      end
    end
  end

  def valid_config
    {
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
