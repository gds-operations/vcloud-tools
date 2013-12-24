module Vcloud
  module Core
    class EdgeGateway

      attr_reader :id

      def initialize(id)
        unless id =~ /^[-0-9a-f]+$/
          raise "EdgeGateway id : #{id} is not in correct format"
        end
        @id = id
      end

      def self.get_ids_by_name(name)
        q = Query.new('edgeGateway', :filter => "name==#{name}")
        unless res = q.get_all_results
          raise "Error finding edgeGateway by name #{name}"
        end
        res.collect do |record| 
          record[:href].split('/').last if record.key?(:href)
        end
      end

      def self.get_by_name(name)
        ids = self.get_ids_by_name(name)
        raise "edgeGateway #{name} not found" if ids.size == 0
        raise "edgeGateway #{name} is not unique" if ids.size > 1
        return self.new(ids.first)
      end

      def vcloud_attributes
        fsi = Vcloud::Fog::ServiceInterface.new
        fsi.get_edge_gateway(id)
      end

      def href
        vcloud_attributes[:href]
      end

      def name
        vcloud_attributes[:name]
      end

    end
  end
end
