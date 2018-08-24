# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'bundler/setup'
require 'sinatra'
require 'sinatra/base'
require 'chef/data_bag_item'

require 'tempfile'
require 'slim'

require 'sinatra/config_file'
require 'pry'
require 'hashdiff'

class ChefDBWM < Sinatra::Application
  register Sinatra::ConfigFile
  set :root, File.dirname(__FILE__) + '/..'
  set :slim, layout: :_layout
  set :public_folder, 'node_modules'

  config_file "config/#{ENV['RACK_ENV']}/config.yml"
  MDB_CONFIG = settings.mdb_config

  use Rack::Logger

  enable :sessions

  helpers do
    def logger
      request.logger
    end
  end
  Bundler.require

  class CheckEncryptedTester
    include Chef::EncryptedDataBagItem::CheckEncrypted
  end

  before do
    @data_bag_dir = MDB_CONFIG['data_bags_path']
    @all_keys = MDB_CONFIG['secret_keys_path']
    @message = session.delete(:message)
  end

  get '/view' do
    bags_dir = {}

    if params[:path]
      real_path = File.realpath(params[:path])
      check_path = @data_bag_dir.map { |databag| real_path.match?(File.realpath(databag['path'])) }

      base_path = File.realpath(real_path)
      bags_dir[base_path] = {}
      root_dir = @data_bag_dir.map { |databag| base_path == File.realpath(databag['path']) }
      Dir.entries("#{base_path}/").each do |item|
        next if item.match?(/^\.$/)
        next if item.match?(/^\.\./) && base_path == @data_bag_dir
        next if item.match?(/^\.\./) && root_dir.include?(true)
        bags_dir[base_path][item] = 'dir' if File.directory?("#{base_path}/#{item}")
        bags_dir[base_path][item] = 'file' if File.file?("#{base_path}/#{item}")
      end
      @data_bags = bags_dir
    else
      @error_message = 'Please specify a good databag'
    end
    if check_path.include? false
      @message = {
        type: 'warning',
        msg: "Path #{params[:path]} not permit.Please check your permission or your configuration file.",
      }
      redirect '/'
    end
    slim :view
  end

  get '/edit' do
    secret_keys = @all_keys.map { |_, secret| secret['path'] }
    @format = 'form'
    encrypted_file = params[:bag_file]
    read_file = File.read(encrypted_file)
    @error = read_file.include?('null') ? 1 : 0
    begin
      encrypted_data = JSON.parse(read_file)
    rescue JSON::ParserError
      @error = 2
    end
    bag_status = CheckEncryptedTester.new
    @plain_data = encrypted_data
    @encrypted = @error == 0 ? bag_status.encrypted?(encrypted_data) : false

    case @error
    when 0
      @secret_file_used = ''
      if @encrypted
        secret_keys.each do |secret_file|
          next unless File.exist?(secret_file)
          secret = Chef::EncryptedDataBagItem.load_secret(secret_file)
          begin
            @plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash
            @error = 0
          rescue StandardError
            @error = 1
          end
          @secret_file_used = secret_file
          break if @error == 0
        end
      end
      type = @plain_data.map { |_, val| val.class }
      msg = type.include?(Hash) ? 'json' : 'form'
      @format = params['format'] ? params['format'] : msg
      @format_link = @format == 'json' ? 'form' : 'json'
      if @error == 1
        @message = {
          type: 'warning',
          msg: "Private key not found to read encrypted databag '#{File.split(encrypted_file).last}'"
        }
      elsif !@message.nil?
        @message = {type: 'info', msg: "Edit format is #{@format}" } if @error == 0
      end
    when 1
      @error = 0
      @plain_data = '' if @plain_data.nil?
      @format = 'json'
      @message = {type: 'info', msg: 'Default edition format is json' }
    when 2
      @message = {type: 'error', msg: "File '#{File.split(params[:bag_file]).last}' is not in JSON format" }
    end
    slim :edit_bag
  end

  post '/edit' do
    @error = 0
    bag_new_data = {}

    if params['format'] == 'json'
      begin
        bag_new_data = JSON.parse(params['content'])
      rescue JSON::ParserError
        @error = 2
      end
    else
      params.select { |param| param.match(/#{params['__id']}/) }.map do |param, val|
        bag_new_data[param.gsub(/#{params['__id']}_/, '')] = val
      end
    end
    if @error != 0
      session[:message] = {type: 'error', msg: "File '#{File.split(params[:bag_file]).last}' is not in JSON format" }
      redirect request.referer
    end

    bag_file = params['bag_file']
    bag_origin_data = JSON.parse(File.read(bag_file))

    if params['encrypted'] == 'true'
      secret = Chef::EncryptedDataBagItem.load_secret(params['secret_key'])
      bag_origin_data_enc = Chef::EncryptedDataBagItem.new(bag_origin_data, secret).to_hash
      diff_get = HashDiff.diff(bag_origin_data_enc, bag_new_data, array_path: true)
      diff_get.each do |diff|
        next if diff.first != '-'
        bag_origin_data.delete(diff[1].first)
      end
      diff_patch = HashDiff.patch!({}, diff_get)
      bag_new_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(diff_patch, secret)
      new_databag = bag_origin_data.merge(bag_new_data)
    else
      diff_get = HashDiff.diff(bag_origin_data, bag_new_data)
      new_databag = HashDiff.patch!(bag_origin_data, diff_get)
    end

    File.open(bag_file, 'w')
    File.write bag_file, "#{JSON.pretty_generate(new_databag)}\n"

    redirect "/edit?bag_file=#{params['bag_file']}"
  end

  get '/create' do
    slim :create_bag
  end

  post '/create' do
    bag_file = "#{params['bag_path']}/#{params['file_name']}.json"
    @error = params['content'].empty? ? 2 : 0
    begin
      data = JSON.parse(params['content'])
      @error = 0
    rescue JSON::ParserError
      @error = 1
      session[:message] = {type: 'error', msg: 'Content field is not in JSON format' }
    end

    if @error == 0
      if params['encrypted'] != 'raw'
        secret = Chef::EncryptedDataBagItem.load_secret(params['encrypted'])
        data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
      end
      File.open(bag_file, 'w')
      File.write bag_file, "#{JSON.pretty_generate(data)}\n"
      session[:message] = {type: 'success', msg: "#{params['file_name']}.json has been created successfully" }
      redirect "/edit?bag_file=#{bag_file}"
    else
      session[:message] = { type: 'error', msg: "File '#{params['file_name']}' is empty or not in JSON format" }
      redirect "/create?bag_path=#{params['bag_path']}", 303
    end
  end

  get '/delete' do
    file_path, file_name = File.split(params[:bag_file])
    begin
      File.delete(params['bag_file'])
      msg = "#{file_name} has been delete."
      type = 'success'
    rescue StandardError
      msg = "An error occured to delete #{file_name}"
      type = 'error'
    end
    session[:message] = {type: type, msg: msg}
    redirect "/view?path=#{file_path}"
  end

  get '/' do
    slim :index
  end

  not_found do
    slim :not_found
  end
  get '/*' do
    redirect '/404', 404
  end
end
