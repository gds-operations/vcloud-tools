require 'vcloud'

module Vcloud
  class ConfigLoader

    def load_config(config_file)
      json_string = File.read(config_file)
      config = JSON.parse(json_string, :symbolize_names => true)
      Deprecator.single_vdc_support if config['vdc']
      config
    end
  end
end
