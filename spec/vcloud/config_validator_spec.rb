require 'spec_helper'

module Vcloud
  describe ConfigValidator do

    it "should validate a basic string" do
      data = "hello world"
      schema = { type: String }
      v = ConfigValidator.validate(data, schema)
      expect(v.valid?).to be_true
    end

  end
end
