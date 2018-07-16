# MIT License
# Copyright (c) 2018 Gauthier FRANÇOIS

require 'bundler/setup'
Bundler.require :default, :development

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'chef-dbwm'

run ChefDBWM
