module Vcloud
  class ConfigValidator

    attr_reader :key, :data, :schema, :type, :errors

    def initialize(key, data, schema)
      raise "Nil schema" unless schema
      raise "Invalid schema" unless schema.key?(:type)
      @type = schema[:type].to_s.downcase
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
      self.send("validate_#{type}".to_sym)
    end

    def self.validate(key, data, schema)
      new(key, data, schema)
    end

    private

    def validate_string
      unless @data.is_a? String
        errors << "#{key}: #{@data} is not a string"
        return
      end
      return unless check_emptyness_ok
    end

    def validate_string_or_number
      unless data.is_a?(String) || data.is_a?(Numeric)
        @errors << "#{key}: #{@data} is not a string_or_number"
        return
      end
    end

    def validate_ip_address
      unless data.is_a?(String)
        @errors << "#{key}: #{@data} is not a valid ip_address"
        return
      end
      invalid = false
      octets = data.split('.')
      if octets.size == 4
        octets.each do |octet|
          invalid = true unless octet.to_i >= 0 && octet.to_i <= 255
        end
      else
        invalid = true
      end
      @errors << "#{key}: #{@data} is not a valid ip_address" if invalid
    end

    def validate_hash
      unless data.is_a? Hash
        @errors << "#{key}: is not a hash"
        return
      end
      return unless check_emptyness_ok
      check_for_unknown_parameters
      if schema.key?(:internals)
        internals = schema[:internals]
        internals.each do |param_key,param_schema|
          check_hash_parameter(param_key, param_schema)
        end
      end
    end

    def validate_array
      unless data.is_a? Array
        @errors << "#{key} is not an array"
        return
      end
      return unless check_emptyness_ok
      if schema.key?(:each_element_is)
        element_schema = schema[:each_element_is]
        data.each do |element|
          sub_validator = ConfigValidator.validate(key, element, element_schema)
          unless sub_validator.valid?
            @errors = errors + sub_validator.errors
          end
        end
      end
    end

    def check_emptyness_ok
      unless schema.key?(:allowed_empty) && schema[:allowed_empty]
        if data.empty?
          @errors << "#{key}: cannot be empty #{type}"
          return false
        end
      end
      true
    end

    def check_hash_parameter(sub_key, sub_schema)
      if sub_schema.key?(:required) && sub_schema[:required] == false
        # short circuit out if we do not have the key, but it's not required.
        return true unless data.key?(sub_key)
      end
      unless data.key?(sub_key)
        @errors << "#{key}: missing '#{sub_key}' parameter"
        return false
      end
      sub_validator = ConfigValidator.validate(
        sub_key,
        data[sub_key],
        sub_schema
      )
      unless sub_validator.valid?
        @errors = errors + sub_validator.errors
      end
    end

    def check_for_unknown_parameters
      unless internals = schema[:internals]
        # if there are no parameters specified, then assume all are ok.
        return true
      end
      if schema[:permit_unknown_parameters]
        return true
      end
      data.keys.each do |k|
        @errors << "#{key}: parameter '#{k}' is invalid" unless internals[k]
      end
    end

  end
end
