# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'bundler/setup'
require 'json'
require 'rspec'
Bundler.require :default, :development

ENV['RACK_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

RSpec::Matchers.define :is_json do |file_name|
  file = JSON.parse(File.read(file_name))
  p file
end
