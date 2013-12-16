module Vcloud
  module Core
    module MetadataHelper

      def extract_metadata vcloud_metadata_entries
        metadata = {}
        vcloud_metadata_entries.each do |entry|
          next unless entry[:type] == Vcloud::Fog::ContentTypes::METADATA
          key = entry[:Key].to_sym
          val = entry[:TypedValue][:Value]
          case entry[:TypedValue][:xsi_type]
            when 'MetadataNumberValue'
              val = val.to_i
            when 'MetadataStringValue'
              val = val.to_s
            when 'MetadataDateTimeValue'
              val = DateTime.parse(val)
            when 'MetadataBooleanValue'
              val = val == 'true' ? true : false
          end
          metadata[key] = val
        end
        metadata
      end

      module_function :extract_metadata
    end
  end
end