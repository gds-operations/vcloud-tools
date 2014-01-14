module Vcloud
  class ConfigValidator

    attr_reader :key, :data, :schema, :errors

    def initialize(key, data, schema)
      @errors = []
      @data   = data
      @schema = schema
      @key    = key
      validate
    end

    def valid?
      @errors.empty?
    end

    def validate
      raise "Nil schema" unless schema
      raise "Invalid schema" unless schema.key?(:type)
      type = @schema[:type].downcase
      self.send("validate_#{type}".to_sym)
    end

    def self.validate(key, data, schema)
      new(key, data, schema)
    end

    private

    def validate_string
      unless @data.is_a? String
        errors << "#{key}: #{@data} is not a string"
      end
    end

    def validate_hash
      unless data.is_a? Hash
        @errors[key] = "#{data} is not a hash"
        return
      end
      if schema.key?(:internals)
        internals = schema[:internals]
        internals.each do |k,v|
          sub_validator = ConfigValidator.validate(k, data[k], internals[k])
          unless sub_validator.valid?
            @errors = errors + sub_validator.errors
          end
        end
      end
    end

  end
end
