require 'vcloud'

module Vcloud
  class Launch

    def initialize
      @cli_options = {}
    end

    def run(config_file = nil, options = {})
      @cli_options = options
      fog_interface = Vcloud::FogInterface.new
      Deprecator.mandatory_input_config_file if config_file.nil?

      puts "cli_options:" if @cli_options[:debug]
      pp @cli_options if @cli_options[:debug]

      config = load_config(config_file)

      config[:vapps].each do |vapp_config|
        Vcloud.logger.info("Configuring vApp #{vapp_config[:name]}.")
        vapp = Vapp.new(fog_interface)
        vapp.provision(vapp_config)
        vapp.power_on unless @cli_options[:no_power_on]
      end
    end

    def load_config(config_file)
      config = YAML::load(File.open(config_file))
      Deprecator.single_vdc_support if config['vdc']

      # slightly dirty hack to get our YAML data into a symbolized key hash :)
      json_string = JSON.generate(config)
      config = JSON.parse(json_string, :symbolize_names => true)
      parse_config(config)
    end

  private
    def parse_config(config)

      parsed_config = {
        :vdcs  => [],
        :vapps => []
      }
      root_defaults = merge_defaults(config[:defaults])
      per_child_defaults = {}

      config[:vdcs].each do |vdc_config|

        vdc_defaults = merge_defaults(vdc_config[:defaults], root_defaults)

        # preserve our purely vDC config in a seperate section
        parsed_config[:vdcs] << { :name => vdc_config[:name] }

        unless vdc_config[:vapp_sets].nil?

          vdc_config[:vapp_sets].each do |vapp_set_config|

            vapp_set_defaults = merge_defaults(vapp_set_config[:defaults], 
                                               vdc_defaults)

            vapp_set_config[:vapps].each do |vapp_config|
              vapp_config[:vdc_name] = vdc_config[:name]
              vapp_config = merge_defaults(vapp_config, 
                                                vapp_set_defaults)

              parsed_config[:vapps] << Vcloud::clone_object(vapp_config)

            end
          end
        end

        # support vapps outside of vapp_sets
        unless vdc_config[:vapps].nil?
          vdc_config[:vapps].each do |vapp_config|
            vapp_config[:vdc_name] = vdc_config[:name]
            vapp_config = merge_defaults(vapp_config, 
                                              vdc_defaults)
            parsed_config[:vapps] << Vcloud::clone_object(vapp_config)
          end
        end


      end

      return parsed_config

    end

    def merge_defaults(data, parent = nil)

      if parent.nil?
        parent = Vcloud::clone_object(Vcloud::Constants::EMPTY_VAPP_DEFAULTS)
      end

      ret = {}
      # keys to transfer from child regardless
      [ :name, :vdc_name ].each do |sym|
        ret[sym] = data[sym] unless data.nil? or data[sym].nil?
      end

      # we need to merge with a cloned object, otherwise ret gets passed 
      # references to the internal hashes and arrays in parent, and subsequently 
      # starts updating them.
      ret = ret.merge(Vcloud::clone_object(parent))

      return ret if data.nil?

      [ :catalog, :catalog_item ].each do |sym|
        ret[sym] = data[sym].nil? ? parent[sym] : data[sym] 
      end

      if data[:vm].is_a?(Hash)
        ret[:vm] = merge_vm_defaults(data[:vm], parent[:vm])
      end

      ret

    end

    def merge_vm_defaults(child, parent)

      ret = Vcloud::clone_object(parent)

      if child[:hardware_config].is_a?(Hash)
        ret[:hardware_config] = parent[:hardware_config].merge(
                child[:hardware_config])
      end

      if child[:metadata].is_a?(Hash)
        ret[:metadata] = parent[:metadata].merge(
                child[:metadata])
      end

      if child[:bootstrap].is_a?(Hash)
        ret[:bootstrap][:script_path] =
              child[:bootstrap][:script_path] ?
                child[:bootstrap][:script_path] :
                  parent[:bootstrap][:script_path]
        if child[:bootstrap][:vars].is_a?(Hash)
          ret[:bootstrap][:vars] =
                parent[:bootstrap][:vars].merge(
                  child[:bootstrap][:vars])
        else
          ret[:bootstrap][:vars] =
                parent[:bootstrap][:vars]
        end
      end

      if child[:network_connections].is_a?(Array)
        # it is much less confusing to overwrite network connections
        ret[:network_connections] = child[:network_connections]
      end

      if child[:extra_disks].is_a?(Array)
        # it is much less confusing to overwrite extra_disks
        ret[:extra_disks] = child[:extra_disks]
      end

      ret

    end
  end
end
