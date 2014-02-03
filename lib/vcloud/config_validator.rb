require 'ipaddr'

module Vcloud
  class ConfigValidator

    attr_reader :key, :data, :schema, :type, :errors

    VALID_ALPHABETICAL_VALUES_FOR_IP_RANGE = %w(any external internal)

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

    def self.validate(key, data, schema)
      new(key, data, schema)
    end

    private

    def validate
      self.send("validate_#{type}".to_sym)
    end

    def validate_string
      unless @data.is_a? String
        errors << "#{key}: #{@data} is not a string"
        return
      end
      return unless check_emptyness_ok
      return unless check_matcher_matches
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
      @errors << "#{key}: #{@data} is not a valid ip_address" unless valid_ip_address?(data)
    end

    def validate_ip_address_range
      unless data.is_a?(String)
        @errors << "#{key}: #{@data} is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'any','internal' and 'external'."
        return
      end
      valid = valid_cidr_or_ip_address? || valid_alphabetical_ip_range? || valid_ip_range?
      @errors << "#{key}: #{@data} is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'any','internal' and 'external'." unless valid
    end

    def valid_cidr_or_ip_address?
      begin
        IPAddr.new(data)
          true
      rescue ArgumentError
        false
      end
    end

    def valid_alphabetical_ip_range?
      VALID_ALPHABETICAL_VALUES_FOR_IP_RANGE.include?(data)
    end

    def valid_ip_address? ip_address
      begin
        #valid formats recognized by IPAddr are : “address”, “address/prefixlen” and “address/mask”.
        # Attribute like member_ip in case of load-balancer is an "address"
        # and we should not accept “address/prefixlen” and “address/mask” for such fields.
        ip = IPAddr.new(ip_address)
        ip && !ip_address.include?('/')
      rescue ArgumentError
        false
      end
    end

    def valid_ip_range?
      range_parts = data.split('-')
      return false if range_parts.size != 2
      start_address = range_parts.first
      end_address = range_parts.last
      valid_ip_address?(start_address) &&  valid_ip_address?(end_address) &&
        valid_start_and_end_address_combination?(end_address, start_address)
    end

    def valid_start_and_end_address_combination?(end_address, start_address)
      start_address_octets = start_address.split('.')
      end_address_octets = end_address.split('.')
      start_address_octets.select.with_index do |octet, index|
        end_address_octets[index] < octet
      end.empty?
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

    def validate_enum
      unless (acceptable_values = schema[:acceptable_values]) && acceptable_values.is_a?(Array)
        raise "Must set :acceptable_values for type 'enum'"
      end
      unless acceptable_values.include?(data)
        acceptable_values_string = acceptable_values.collect {|v| "'#{v}'" }.join(', ')
        @errors << "#{key}: #{@data} is not a valid value. Acceptable values are #{acceptable_values_string}."
      end
    end

    def validate_boolean
      unless [true, false].include?(data)
        @errors << "#{key}: #{data} is not a valid boolean value."
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

    def check_matcher_matches
      return unless regex = schema[:matcher]
      raise "#{key}: #{regex} is not a Regexp" unless regex.is_a? Regexp
      unless data =~ regex
        @errors << "#{key}: #{data} does not match"
        return false
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
