require 'spec_helper'

module Vcloud
  describe ConfigValidator do

    context "string validations" do

      it "should validate a basic string" do
        data = "hello world"
        schema = { type: "String" }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should not validate a number as a basic string" do
        data = 42
        schema = { type: "String" }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_false
      end

      it "should log error with number as a basic string" do
        data = 42
        schema = { type: "String" }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: 42 is not a string'] )
      end

    end

    context "hash validations" do

      it "should validate a basic hash" do
        data = { name: "santa", address: "north pole" }
        schema = {
          type: "Hash",
          internals: {
            name: { type: "String" },
            address: { type: "String" },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should not validate a bogus hash" do
        data = { name: 42, address: 42 }
        schema = {
          type: "Hash",
          internals: {
            name: { type: "String" },
            address: { type: "String" },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_false
      end

      it "should return correct errors validating a bogus hash" do
        data = { name: 42, address: 42 }
        schema = {
          type: "Hash",
          internals: {
            name: { type: "String" },
            address: { type: "String" },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([
          "name: 42 is not a string",
          "address: 42 is not a string",
        ])
      end

    end

  end
end
