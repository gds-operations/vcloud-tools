module Vcloud
  module Core
    class VappTemplate

      attr_reader :id

      def initialize(id)
        unless id =~ /^#{self.class.id_prefix}-[-0-9a-f]+$/
          raise "#{self.class.id_prefix} id : #{id} is not in correct format"
        end
        @id = id
      end

      def vcloud_attributes
        Vcloud::Fog::ServiceInterface.new.get_vapp_template(id)
      end

      def self.get catalog_name, catalog_item_name
        raise "provide catalog and catalog item name to load vappTemplate" unless catalog_name && catalog_item_name
        body = Vcloud::Fog::ServiceInterface.new.template(catalog_name, catalog_item_name)
        raise 'Could not find template vApp' unless body && body.key?(:href)
        self.new(body[:href].split('/').last)
      end

      def self.id_prefix
        'vappTemplate'
      end

    end
  end
end
