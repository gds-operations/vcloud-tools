require 'vcloud'

module Vcloud
  module EdgeGateway
    class EdgeGatewayConfiguration

      def initialize(local_config)
        @local_config = local_config
      end

      def update_required?(remote_config)
        true
      end

      def config

      end

    end
  end
end
