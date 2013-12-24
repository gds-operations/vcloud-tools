module Vcloud
  module Core
    class OrgVdcNetwork

      attr_reader :id

      def initialize(id)
        unless id =~ /^[-0-9a-f]+$/
          raise "orgVdcNetwork id : #{id} is not in correct format"
        end
        @id = id
      end

      def self.get_by_name(name)
        q = Query.new('orgVdcNetwork', :filter => "name==#{name}")
        unless res = q.get_all_results
          raise "Error finding orgVdcNetwork by name #{name}"
        end
        case res.size
        when 0
          raise "orgVdcNetwork #{name} not found"
        when 1
          return self.new(res.first[:href].split('/').last)
        else
          raise "found multiple orgVdcNetwork with name #{name}!"
        end
      end

      def vcloud_attributes
        Vcloud::Fog::ServiceInterface.new.get_network(id)
      end

      def name
        vcloud_attributes[:name]
      end

      def href
        vcloud_attributes[:href]
      end

      def delete
        Vcloud::Fog::ServiceInterface.new.delete_network(id)
      end

    end
  end
end
