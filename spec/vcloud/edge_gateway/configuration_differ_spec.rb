require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe ConfigurationDiffer do

      test_cases = [
        {
          title: 'should return an empty array for two identical empty Hashes',
          src:    { },
          dest:   { },
          output: [],
        },

        {
          title: 'should return an empty array for two identical simple Hashes',
          src:    { testing: 'testing', one: 1, two: 'two', three: "3" },
          dest:   { testing: 'testing', one: 1, two: 'two', three: "3" },
          output: [],
        },

        {
          title: 'should return an empty array for two identical deep Hashes',
          src:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          dest:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [],
        },

        {
          title: 'should highlight a simple addition',
          src:    { foo: '1' },
          dest:   { foo: '1', bar: '2' },
          output: [["+", "bar", "2"]],
        },

        {
          title: 'should highlight a simple subtraction',
          src:    { foo: '1', bar: '2' },
          dest:   { foo: '1' },
          output: [["-", "bar", "2"]],
        },

        {
          title: 'should highlight a deep addition',
          src:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          dest:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5, 6 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [["+", "deep[0].deeper[5]", 6]],
        },

        {
          title: 'should highlight a deep subtraction',
          src:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          dest:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 3, 2 ] },
          ]},
          output: [["-", "deep[1].deeper[2]", 4]],
        },

        {
          title: 'should return an empty array when hash params are reordered',
          src:    { one: 1, testing: 'testing', deep: [
            { deeper: [ 1, 2, 3, 4, 5 ], foo: 'bar' },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          dest:   { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [],
        },

        {
          title: 'should highlight when array elements are reordered',
          src:    { testing: 'testing', one: 1, deep: [
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
          ]},
          dest:   { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [
            ["+", "deep[0]", {:foo=>"bar", :deeper=>[1, 2, 3, 4, 5]}],
            ["-", "deep[2]", {:foo=>"bar", :deeper=>[1, 2, 3, 4, 5]}],
          ]
        },

        {
          title: 'should highlight when deep array elements are reordered',
          src:    { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 5, 6, 4, 3, 2 ] },
          ]},
          dest:   { testing: 'testing', one: 1, deep: [
            { foo: 'bar', deeper: [ 1, 2, 3, 4, 5 ] },
            { baz: 'bop', deeper: [ 6, 5, 4, 3, 2 ] },
          ]},
          output: [
            ["+", "deep[1].deeper[0]", 6],
            ["-", "deep[1].deeper[2]", 6]
          ]
        },

      ]

      test_cases.each do |test_case|
        it "#{test_case[:title]}" do
          differ = ConfigurationDiffer.new(test_case[:src], test_case[:dest])
          expect(differ.diff).to eq(test_case[:output])
        end
      end

    end
  end
end
