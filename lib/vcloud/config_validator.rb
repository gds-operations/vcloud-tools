module Vcloud
  class ConfigValidator

    def initialize(data, schema)
      @errors = {}
      @data   = data
      @schema = schema
    end

    def valid?
      @errors.empty?
    end

    def self.validate(data, schema)
      new(data, schema)
    end

  end
end
