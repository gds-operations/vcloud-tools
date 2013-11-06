module Vcloud
  module Constants

    EMPTY_VAPP_DEFAULTS = {
      :catalog      => nil,
      :catalog_item => nil,
      :vm => {
        :hardware_config => {},
        :extra_disks     => [],
        :network_connections => [],
        :bootstrap       => {
          :script_path => nil,
          :vars => {},
        },
        :metadata => {},
      },
    }

  end
end
