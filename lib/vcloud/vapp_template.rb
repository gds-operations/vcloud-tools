module Vcloud
  class VappTemplate < Entity

    def initialize(vcloud_attributes)
      @vcloud_attributes = vcloud_attributes
    end

    def self.get catalog_name, catalog_item_name
      raise "provide catalog and catalog item name to load vappTemplate" unless catalog_name && catalog_item_name
      @vcloud_attributes = Vcloud::Fog::ServiceInterface.new.template(catalog_name, catalog_item_name)
      raise 'Could not find template vApp' unless @vcloud_attributes
      new(@vcloud_attributes)
    end

    def id_prefix
      'vappTemplate'
    end

  end
end
