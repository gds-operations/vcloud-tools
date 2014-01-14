module Vcloud
  class ConfigValidator

    attr_reader :data, :schema, :errors

    def initialize(key, data, schema)
      @errors = {}
      @data   = data
      @schema = schema
      @key    = key
      validate
    end

    def valid?
      @errors.empty?
    end

    def validate
      raise "Invalid schema" unless @schema.key?(:type)
      type = @schema[:type].downcase
      self.send("validate_#{type}".to_sym)
    end

    def self.validate(key, data, schema)
      new(key, data, schema)
    end

    private

    def validate_string
      unless @data.is_a? String
        @errors[@key] = "#{@data} is not a string"
      end
    end

  end
end
