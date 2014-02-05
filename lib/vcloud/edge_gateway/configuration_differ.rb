require 'vcloud'

module Vcloud
  module EdgeGateway
    class ConfigurationDiffer

        def initialize local, remote
          @local = local
          @remote = remote
        end

        def diff
          ( @local == @remote ) ? [] : HashDiff.diff(@local, @remote)
        end

    end
  end

end
