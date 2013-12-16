module Vcloud
  module Core
    class Entity

      def id_prefix;
        raise 'id_prefix : method missing'
      end

      def id
        raise 'id not found' unless @vcloud_attributes && @vcloud_attributes[:href]
        extracted_id = @vcloud_attributes[:href].split('/').last
        unless extracted_id =~ /^#{id_prefix}-[-0-9a-f]+$/
          raise "#{id_prefix} id : #{extracted_id} is not in correct format"
        end
        extracted_id
      end

      def name
        @vcloud_attributes[:name]
      end
    end
  end
end
