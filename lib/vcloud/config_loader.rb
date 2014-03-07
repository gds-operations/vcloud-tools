require 'vcloud'

module Vcloud
  class ConfigLoader

    def load_config(config_file, schema = nil)
      input_config = YAML::load(File.open(config_file))

      # There is no way in YAML or Ruby to symbolize keys in a hash
      json_string = JSON.generate(input_config)
      config = JSON.parse(json_string, :symbolize_names => true)

      if schema
        validation = Vcloud::Core::ConfigValidator.validate(:base, config, schema)
        unless validation.valid?
          validation.errors.each do |error|
            Vcloud.logger.fatal(error)
          end
          raise("Supplied configuration does not match supplied schema")
        end
      end
      config
    end

  end 
end
