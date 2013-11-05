#!/usr/bin/env ruby
#
require 'yaml'
require 'json'

file = ARGV.shift

data = YAML::load(File.open(file))
json_string = JSON.generate(data)
symbolized = JSON.parse(json_string, :symbolize_names => true)
puts YAML::dump(symbolized)

