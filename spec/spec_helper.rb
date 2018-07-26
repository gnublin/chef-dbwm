# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'bundler/setup'
require 'rspec'
Bundler.require :default, :development

ENV['RACK_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
