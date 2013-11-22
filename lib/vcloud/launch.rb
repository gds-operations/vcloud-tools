require 'vcloud'

module Vcloud
  class Launch

    def initialize
      @cli_options = {}
      @config_loader = Vcloud::ConfigLoader.new
    end

    def run(config_file = nil, options = {})
      @cli_options = options
      fog_interface = Vcloud::FogServiceInterface.new
      Deprecator.mandatory_input_config_file if config_file.nil?

      puts "cli_options:" if @cli_options[:debug]
      pp @cli_options if @cli_options[:debug]

      config = @config_loader.load_config(config_file)

      config[:vapps].each do |vapp_config|
        Vcloud.logger.info("Configuring vApp #{vapp_config[:name]}.")
        vapp = Vapp.new(fog_interface)
        vapp.provision(vapp_config)
        vapp.power_on unless @cli_options[:no_power_on]
      end
    end

  end
end
