require 'spec_helper'

module Vcloud
  module Core
    describe MetadataHelper do
      context "get_metadata" do

        it "should process valid metadata types" do
          metadata_entries = [
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => 'role_name',
                  :TypedValue => {
                      :xsi_type => 'MetadataStringValue',
                      :Value => 'james-bond'
                  }},
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => "server_number",
                  :TypedValue => {:xsi_type => "MetadataNumberValue", :Value => "-10"}
              },
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => "created_at",
                  :TypedValue => {:xsi_type => "MetadataDateTimeValue", :Value => "2013-12-16T14:30:05.000Z"}
              },
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => "daily_shutdown",
                  :TypedValue => {:xsi_type => "MetadataBooleanValue", :Value => "false"}
              }
          ]
          metadata = MetadataHelper.extract_metadata(metadata_entries)
          metadata.count.should == 4
          metadata[:role_name].should == 'james-bond'
          metadata[:server_number].should == -10
          metadata[:created_at].should == DateTime.parse("2013-12-16T14:30:05.000Z")
          metadata[:daily_shutdown].should == false
        end

        it "should skip metadata entry if entry type is not application/vnd.vmware.vcloud.metadata.value+xml" do
          metadata_entries = [
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => 'role_name',
                  :TypedValue => {
                      :xsi_type => 'MetadataStringValue',
                      :Value => 'james-bond'
                  }},
              {
                  :Key => "untyped_key",
                  :TypedValue => {:xsi_type => "MetadataNumberValue", :Value => "-10"}
              },

          ]
          metadata = MetadataHelper.extract_metadata(metadata_entries)
          metadata.count.should == 1
          metadata.keys.should_not include :untyped_key
        end

        it "should include unrecognized metadata types" do
          metadata_entries = [
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => 'role_name',
                  :TypedValue => {
                      :xsi_type => 'MetadataStringValue',
                      :Value => 'james-bond'
                  }},
              {
                  :type => Fog::ContentTypes::METADATA,
                  :Key => "unrecognized_type_key",
                  :TypedValue => {:xsi_type => "MetadataWholeNumberValue", :Value => "-10"}
              },

          ]
          metadata = MetadataHelper.extract_metadata(metadata_entries)
          metadata.count.should == 2
          metadata.keys.should include :unrecognized_type_key
        end


      end


    end

  end
end
