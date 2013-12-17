module Vcloud
  module Core
    module ComputeMetadata

        def get_metadata id
          vcloud_compute_metadata =  Vcloud::Fog::ServiceInterface.new.get_vapp_metadata(id)
          MetadataHelper.extract_metadata(vcloud_compute_metadata[:MetadataEntry])
        end

    end
  end
end

