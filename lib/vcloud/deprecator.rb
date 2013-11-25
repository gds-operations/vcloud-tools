module Vcloud
  class Deprecator

    def self.single_vdc_support
      logger = Vcloud.logger

      logger.info('Config file format has changed. vDCs now specified as:')
      logger.info('  vdcs:')
      logger.info('    - name: "vDC 1"')
      logger.info('    - name: "vDC 2"')
      logger.info('See spec/data/machines.yaml for an example')

      Kernel.exit
    end

    def self.mandatory_input_config_file
      logger = Vcloud.logger

      logger.info('Vcloud::Launch.run now needs config_file passed as single argument.')
      logger.info('Ideally you should be using the vcloud-launch CLI tool, which now')
      logger.info('has a shiny options interface')

      Kernel.exit
    end

    def self.old_yaml_format
      logger = Vcloud.logger

      logger.info('Config file format has changed.')
      logger.info('Please use YAML anchors to specify defaults.')

      Kernel.exit
    end

  end
end
