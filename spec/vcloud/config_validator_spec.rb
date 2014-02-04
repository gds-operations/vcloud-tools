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

      it "should return error with empty string (by default)" do
        data = ""
        schema = { type: 'string' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty string'] )
      end

      it "should return error with empty string with allowed_empty: false)" do
        data = ""
        schema = { type: 'string', allowed_empty: false }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty string'] )
      end

      it "should validate ok with empty string with allowed_empty: true)" do
        data = ""
        schema = { type: 'string', allowed_empty: true }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should validate ok with a :matcher regex specified" do
        data = "name-1234"
        schema = { type: 'string', matcher: /^name-\d+$/ }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should return errror with a :matcher regex not matching" do
        data = "name-123a"
        schema = { type: 'string', matcher: /^name-\d+$/ }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(['base: name-123a does not match'])
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

      it "should return error with empty hash (by default)" do
        data = {}
        schema = { type: 'hash' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty hash'] )
      end

      it "should return error with empty hash with allowed_empty: false)" do
        data = {}
        schema = { type: 'hash', allowed_empty: false }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty hash'] )
      end

      it "should validate ok with empty hash with allowed_empty: true)" do
        data = {}
        schema = { type: 'hash', allowed_empty: true }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should validate ok with a missing parameter, when marked :required => false" do
        data = {
          name: 'hello'
        }
        schema = {
          type: 'hash',
          internals: {
            name: { type: 'string' },
            optional_param: { type: 'string', required: false },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should return error with a missing :required => true param" do
        data = {
          name: 'hello'
        }
        schema = {
          type: 'hash',
          internals: {
            name: { type: 'string' },
            not_optional_param: { type: 'string', required: true },
          }
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(["base: missing 'not_optional_param' parameter"])
      end

      it "should return error if a bogus parameter is specified" do
        data = {
          name: 'hello',
          bogus_parameter: [ 'wibble' ],
          bogus_parameter2: 'hello',
        }
        schema = {
          type: 'hash',
          internals: {
            name: { type: 'string' },
          },
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([
          "base: parameter 'bogus_parameter' is invalid",
          "base: parameter 'bogus_parameter2' is invalid",
        ])
      end

      it "should validate ok if a bogus parameter is specified, when :permit_unknown_parameters is true" do
        data = {
          name: 'hello',
          bogus_parameter: [ 'wibble' ],
          bogus_parameter2: 'hello',
        }
        schema = {
          type: 'hash',
          permit_unknown_parameters: true,
          internals: {
            name: { type: 'string' },
          },
        }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
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

      it "should return error with empty array (by default)" do
        data = []
        schema = { type: 'array' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty array'] )
      end

      it "should return error with empty array with allowed_empty: false)" do
        data = []
        schema = { type: 'array', allowed_empty: false }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq([ 'base: cannot be empty array'] )
      end

      it "should validate ok with empty array with allowed_empty: true)" do
        data = []
        schema = { type: 'array', allowed_empty: true }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
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

    context "string_or_number validations" do

      it "should correctly validate an Integer" do
        data = 2
        schema = { type: 'string_or_number' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should correctly validate a String" do
        data = '2'
        schema = { type: 'string_or_number' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should correctly error if not a string or numeric" do
        data = []
        schema = { type: 'string_or_number' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(["base: [] is not a string_or_number"])
      end

    end

    context "ip_address validations" do

      it "should correctly validate an IP address" do
        data = '192.168.100.100'
        schema = { type: 'ip_address' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end

      it "should correctly error on an invalid IP address" do
        data = '256.168.100.100'
        schema = { type: 'ip_address' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(['base: 256.168.100.100 is not a valid ip_address'])
      end

      it "should error if ip address have wrong octets" do
        data = '192.168.100.100/33/33/33'
        schema = { type: 'ip_address' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(['base: 192.168.100.100/33/33/33 is not a valid ip_address'])
      end

    end

    context "ip_address_range validations" do
      context "validate CIDR" do
        it "should validate OK if CIDR is correct" do
          data = '192.168.100.100/24'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_true
        end

        it "should return error if network bit value is greater than 32" do
          data = '192.168.100.100/33'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 192.168.100.100/33 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end

        it "should return error if network bit value is less than 0" do
          data = '192.168.100.100/33'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 192.168.100.100/33 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end

        it "should return error if network IP address is incorrect" do
          data = '192.168.100./33'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 192.168.100./33 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end
      end

      context "validate alphabetical values for IP range" do
        %w(Any internal external).each do |data|
          it "should validate OK if IP range is '#{data}'" do
            schema = { type: 'ip_address_range' }
            v = ConfigValidator.validate(:base, data, schema)
            expect(v.valid?).to be_true
            expect(v.errors).to be_empty
          end
        end

        it "should error if IP range is a string but not a valid alphabetical value" do
          data = 'invalid_ip_range_string'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: invalid_ip_range_string is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end
      end

      context "validate ranges specified using start and end addresses" do
        it "should validate ok if the combination of start IP and end IP is correct" do
          data = '192.168.100.100-192.168.100.110'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_true
          expect(v.errors).to be_empty
        end

        it "should error if start IP address is incorrect" do
          data = '192.168.100-192.168.100.110'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 192.168.100-192.168.100.110 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end

        it "should error if end IP address is incorrect" do
          data = '192.168.100.110-192.168.100'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 192.168.100.110-192.168.100 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end

        it "should error if the combination of start IP and end IP is incorrect" do
          data = '200.168.100.99-192.168.100'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 200.168.100.99-192.168.100 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end

        it "should error if the start and end IPS are not separated by -" do
          data = '190.168.100.99:192.168.100'
          schema = { type: 'ip_address_range' }
          v = ConfigValidator.validate(:base, data, schema)
          expect(v.valid?).to be_false
          expect(v.errors).to eq(["base: 190.168.100.99:192.168.100 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'."])
        end
      end

      it "should accept single ip address as range" do
        data = '190.168.100.99'
        schema = { type: 'ip_address_range' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
        expect(v.errors).to eq([])
      end
    end

    context "enum validations" do
      it "should error if enum value is not present in list" do
        data = 'blah'
        schema = { type: 'enum', required: false, acceptable_values: ['allow', 'decline', 'none']}
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(["base: blah is not a valid value. Acceptable values are 'allow', 'decline', 'none'."])
      end

      it "should raise error if enum schema does not contain acceptable_values" do
        data = 'blah'
        schema = { type: 'enum', required: false}
        expect{ ConfigValidator.validate(:base, data, schema) }.to raise_error("Must set :acceptable_values for type 'enum'")
      end

      it "should validate ok if enum is acceptable" do
        data = 'allow'
        schema = { type: 'enum', required: false, acceptable_values: ['allow', 'decline', 'none']}
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.valid?).to be_true
      end
    end

    context "boolean validations" do
      it "should error if boolean value is not valid" do
        data = 'blah'
        schema = { type: 'boolean' }
        v = ConfigValidator.validate(:base, data, schema)
        expect(v.errors).to eq(["base: blah is not a valid boolean value."])
      end

      [true, false].each do |boolean_value|
        it "should validate ok if value is #{boolean_value}" do
          schema = { type: 'boolean' }
          v = ConfigValidator.validate(:base, boolean_value, schema)
          expect(v.valid?).to be_true
        end
      end

    end

  end
end
