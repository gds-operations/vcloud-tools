module Vcloud
  module Fog
    module ContentTypes
      CATALOG = 'application/vnd.vmware.vcloud.catalog+xml'
      ORG = 'application/vnd.vmware.vcloud.org+xml'
      VDC = 'application/vnd.vmware.vcloud.vdc+xml'
      CATALOG_ITEM = 'application/vnd.vmware.vcloud.catalogItem+xml'
      NETWORK = 'application/vnd.vmware.vcloud.network+xml'
      METADATA = 'application/vnd.vmware.vcloud.metadata.value+xml'
    end

    module MetadataValueType
      String = 'MetadataStringValue'
      Number = 'MetadataNumberValue'
      DateTime = 'MetadataDateTimeValue'
      Boolean = 'MetadataBooleanValue'
    end

  end
end
