require 'spec_helper'
require 'vcloud/config_loader'

module Vcloud


  describe Vcloud::ConfigLoader do

    before(:all) do
      @data_dir = File.join(File.dirname(__FILE__), "../data")
    end

    context "parsing the configuration" do

      describe "#load_config" do
        it "should correctly parse all valid configurations" do
          Dir.entries(@data_dir).each do |file|
            next unless file =~ /\.yaml$/
            full_path = File.join(@data_dir, file)
            expected_data = YAML::load(File.open("#{full_path}.parsed"))
            Vcloud::ConfigLoader.new.load_config(full_path).should == expected_data
          end
        end
      end

    end

  end
end
