require 'vcloud'

module Vcloud
  module EdgeGateway
    class LoadBalancerConfigurationDiffer

        def initialize local, remote
          @local = local
          @remote = remote
        end

        def diff
          ( @local == stripped_remote_config ) ? [] : HashDiff.diff(@local, stripped_remote_config)
        end

        def stripped_remote_config
          deep_cloned_remote_config = Marshal.load( Marshal.dump(@remote) )
          if deep_cloned_remote_config.key?(:Pool)
            deep_cloned_remote_config[:Pool].each do |pool_entry|
              pool_entry.delete(:Operational)
            end
          end
          deep_cloned_remote_config
        end

    end
  end

end
