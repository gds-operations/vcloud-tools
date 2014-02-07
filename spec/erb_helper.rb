class ErbHelper
  def self.generate_input_yaml_config test_namespace, input_erb_config
    input_erb_config = input_erb_config
    e = ERB.new(File.open(input_erb_config).read)
    output_yaml_config = File.join(File.dirname(input_erb_config), "output_#{Time.now.strftime('%s')}.yaml")
    File.open(output_yaml_config, 'w') { |f|
      f.write e.result(OpenStruct.new(test_namespace).instance_eval { binding })
    }
    output_yaml_config
  end
end
