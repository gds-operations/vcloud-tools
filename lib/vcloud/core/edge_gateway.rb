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

      def self.get_by_name(name)
        q = Query.new('edgeGateway', :filter => "name==#{name}")
        unless res = q.get_all_results
          raise "Error finding edgeGateway by name #{name}"
        end
        raise "edgeGateway #{name} not found" unless res.size == 1
        return self.new(res.first[:href].split('/').last)
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
