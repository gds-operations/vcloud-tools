require 'vcloud'

module Vcloud
  class Launch

    def initialize
      @config_loader = Vcloud::ConfigLoader.new
    end

    def run(config_file = nil, cli_options = {})
      puts "cli_options:" if cli_options[:debug]
      pp cli_options if cli_options[:debug]

      config = @config_loader.load_config(config_file)
      config[:vapps].each do |vapp_config|
        Vcloud.logger.info("Configuring vApp #{vapp_config[:name]}.")
        begin
          vapp = ::Vcloud::VappOrchestrator.provision(vapp_config)
          vapp.power_on unless cli_options[:no_power_on]
        rescue RuntimeError => e
          Vcloud.logger.error("Could not provision vApp: #{e.message}")
          break unless cli_options[:continue_on_error]
        end
      end
    end

  end
end
