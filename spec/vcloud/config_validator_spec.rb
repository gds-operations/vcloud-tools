require 'spec_helper'

module Vcloud
  describe ConfigValidator do

    context "sanitize type" do

      it "should be ok with type as bare String" do
        data = "hello world"
        schema = { type: String }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should be ok with type as string 'String'" do
        data = "hello world"
        schema = { type: 'String' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should be ok with type as string 'string'" do
        data = "hello world"
        schema = { type: 'string' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

    end

    context "string validations" do

      it "should validate a basic string" do
        data = "hello world"
        schema = { type: 'string' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should not validate a number as a basic string" do
        data = 42
        schema = { type: 'string' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_false
      end

      it "should log error with number as a basic string" do
        data = 42
        schema = { type: 'string' }
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
            name: { type: 'string' },
            address: { type: 'string' },
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
            name: { type: "string" },
            address: { type: "string" },
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
            name: { type: "string" },
            address: { type: "string" },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([
          "name: 42 is not a string",
          "address: 42 is not a string",
        ])
      end

    end

    context "array validations" do

      it "should validate a basic array" do
        data = [ "santa", "north pole" ]
        schema = {
          type: "Array",
          each_element_is: { type: "string" }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should validate a bogus array" do
        data = [ 42, 43 ]
        schema = {
          type: "Array",
          each_element_is: { type: "string" }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_false
      end

      it "should return correct errors validating a bogus array" do
        data = [ 42, 43 ]
        schema = {
          type: "Array",
          each_element_is: { type: "string" }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([
          "base: 42 is not a string",
          "base: 43 is not a string",
        ])
      end

    end

    context "array of hashes validations" do

      it "should validate an array of hashes" do
        data = [
          { name: "santa", address: "north pole" },
          { name: "mole",  address: "1 hole street" },
        ]
        schema = {
          type: "array",
          each_element_is: {
            type: "hash",
            internals: {
              name: { type: 'string' },
              address: { type: 'string' },
            }
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should correctly error on an invalid an array of hashes" do
        data = [
          { name: "santa", address: [] },
          { name: 43,  address: "1 hole street" },
        ]
        schema = {
          type: "array",
          each_element_is: {
            type: "hash",
            internals: {
              name: { type: 'string' },
              address: { type: 'string' },
            }
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([
          "address: [] is not a string",
          "name: 43 is not a string",
        ])
      end

    end

    context "hash of arrays validations" do

      it "should validate a hash of arrays" do
        data = {
          boys_names: [ 'bob', 'andrew', 'charlie', 'dave' ],
          girls_names: [ 'alice', 'beth', 'carol', 'davina' ],
        }
        schema = {
          type: "Hash",
          internals: {
            boys_names: {
              type: "Array",
              each_element_is: { type: 'String' }
            },
            girls_names: {
              type: "Array",
              each_element_is: { type: 'String' }
            }
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should correctly error on an invalid hash of arrays" do
        data = {
          boys_names: [ 'bob', 'andrew', 'charlie', 'dave' ],
          girls_names: [ 'alice', 'beth', 'carol', 'davina' ],
        }
        schema = {
          type: "Hash",
          internals: {
            boys_names: {
              type: "Array",
              each_element_is: { type: 'String' },
            },
            girls_names: {
              type: "Array",
              each_element_is: { type: 'String' },
            }
          },
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

    end

  end
end
