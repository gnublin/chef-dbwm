# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'bundler/setup'
Bundler.require :default, :development

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'chef-dbwm'

run ChefDBWM
