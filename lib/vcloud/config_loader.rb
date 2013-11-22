require 'vcloud'

module Vcloud
  class ConfigLoader

    def load_config(config_file)
      config = YAML::load(File.open(config_file))

      # We have to use this hack again if we are to do everything in YAML
      # better might be to write a symbolize keys method?
      json_string = JSON.generate(config)
      config = JSON.parse(json_string, :symbolize_names => true)

      Deprecator.single_vdc_support if config['vdc']
      config
    end
  end

end
