require 'vcloud'

module Vcloud
  class Launch

    def initialize
      @config_loader = Vcloud::Core::ConfigLoader.new
    end

    def run(config_file = nil, cli_options = {})
      config = @config_loader.load_config(config_file, config_schema)
      config[:vapps].each do |vapp_config|
        Vcloud.logger.info("\n")
        Vcloud.logger.info("Provisioning vApp #{vapp_config[:name]}.")
        begin
          vapp = ::Vcloud::VappOrchestrator.provision(vapp_config)
          #methadone sends option starting with 'no' as false.
          vapp.power_on unless cli_options["dont-power-on"]
          Vcloud.logger.info("Done! Provisioned vApp #{vapp_config[:name]} successfully.")
          Vcloud.logger.info("=" * 70)
        rescue RuntimeError => e
          Vcloud.logger.error("Failure : Could not provision vApp: #{e.message}")
          Vcloud.logger.info("=" * 70)
          break unless cli_options["continue-on-error"]
        end

      end
    end

    def config_schema
      {
        type: 'hash',
        allowed_empty: false,
        permit_unknown_parameters: true,
        internals: {
          vapps: {
            type: 'array',
            required: false,
            allowed_empty: true,
            each_element_is: ::Vcloud::VappOrchestrator.provision_schema
          },
        }
      }
    end

  end
end
