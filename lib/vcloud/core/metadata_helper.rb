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
            when Fog::MetadataValueType::Number
              val = val.to_i
            when Fog::MetadataValueType::String
              val = val.to_s
            when Fog::MetadataValueType::DateTime
              val = DateTime.parse(val)
            when Fog::MetadataValueType::Boolean
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
