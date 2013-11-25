require 'vcloud'

module Vcloud
  class ConfigLoader

    def load_config(config_file)
      config = YAML::load(File.open(config_file))
      Deprecator.old_yaml_format if config['defaults']

      # There is no way in YAML or Ruby to symbolize keys in a hash
      json_string = JSON.generate(config)
      config = JSON.parse(json_string, :symbolize_names => true)

      Deprecator.single_vdc_support if config['vdc']
      config
    end

  end 
end
