# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'bundler/setup'
require 'sinatra'
require 'sinatra/base'
require 'chef/data_bag_item'

require 'tempfile'
require 'slim'
require 'yaml'
require 'find'

require 'sinatra/config_file'
require 'pry'
require 'hashdiff'

class ChefDBWM < Sinatra::Application
  register Sinatra::ConfigFile
  set :root, File.dirname(__FILE__) + '/..'
  set :slim, layout: :_layout
  set :public_folder, 'node_modules'

  path_config_file = "config/#{ENV['RACK_ENV']}/config.yml"
  config_file path_config_file
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
    @path_config_file = path_config_file
    @data_bag_dir = MDB_CONFIG['data_bags_path']
    @all_keys = MDB_CONFIG['secret_keys_path']
    @message = session.delete(:message)
  end

  get '/view' do
    bags_dir = {}

    if params[:path]
      data_bag_name, relative_path = params[:path].split(':')

      redirect '/' if data_bag_name.nil?

      base_path = @data_bag_dir[data_bag_name]
      bags_dir[data_bag_name] = {}

      unless relative_path.nil?
        base_path = nil if relative_path.match?(%r{^../$})
        base_path = nil if relative_path.match?(/^\.\./)
        base_path = nil if relative_path.match?(%r{^/\.\.})
        base_path = nil if relative_path.match?(%r{/^!//})
      end

      if base_path.nil?
        @message = {
          type: 'warning',
          msg: "Path #{params[:path]} not permit.Please check your permission or your configuration file.",
        }
        redirect "/view?path=#{data_bag_name}:" unless @data_bag_dir[data_bag_name].nil?
        redirect '/404'
      end

      begin
        base_path = File.realpath("#{base_path}#{relative_path}")
      rescue Errno::ENOENT
        redirect '/404'
      end
      Dir.entries("#{base_path}/").each do |item|
        next if item.match?(/^\.$/)
        next if item.match?(/^\.\./) && relative_path.nil?
        bags_dir[data_bag_name][item] = 'dir' if File.directory?("#{base_path}/#{item}")
        bags_dir[data_bag_name][item] = 'file' if File.file?("#{base_path}/#{item}")
      end
      @data_bags = bags_dir
    else
      @error_message = 'Please specify a good data bag'
    end

    @data_bag_path = base_path.gsub(File.realpath(@data_bag_dir[data_bag_name]), '') unless relative_path.nil?
    slim :view
  end

  get '/edit' do
    data_bag_name, relative_path = params[:bag_file].split(':')
    base_path = @data_bag_dir[data_bag_name]
    begin
      file_path = File.realpath("#{base_path}/#{relative_path}") unless relative_path.nil?
    rescue Errno::ENOENT
      redirect '/404'
    end

    secret_keys = @all_keys.map { |_, secret| secret['path'] }
    @format = 'form'
    read_file = File.read(file_path)
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
      @ordered_data = {'id' => @plain_data.delete('id')}
      @plain_data = @ordered_data.merge(Hash[@plain_data.sort])
      if @error == 1
        @message = {
          type: 'warning',
          msg: "Private key not found to read encrypted data bag '#{File.split(file_path).last}'"
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

    data_bag_name, relative_path = params[:bag_file].split(':')
    base_path = @data_bag_dir[data_bag_name]
    bag_file = File.realpath("#{base_path}/#{relative_path}") unless relative_path.nil?
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
      new_data_bag = bag_origin_data.merge(bag_new_data)
    else
      diff_get = HashDiff.diff(bag_origin_data, bag_new_data)
      new_data_bag = HashDiff.patch!(bag_origin_data, diff_get)
    end

    File.open(bag_file, 'w')
    File.write bag_file, "#{JSON.pretty_generate(new_data_bag)}\n"

    redirect "/edit?bag_file=#{params['bag_file']}"
  end

  get '/create' do
    slim :create_bag
  end

  post '/create' do
    data_bag_name, relative_path = params[:bag_path].split(':')
    base_path = @data_bag_dir[data_bag_name]
    base_path = "#{base_path}/#{relative_path}" unless relative_path.nil?
    bag_file = "#{base_path}/#{params['file_name']}.json"
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
      redirect "/edit?bag_file=#{data_bag_name}:#{relative_path}/#{params['file_name']}.json"
    else
      session[:message] = { type: 'error', msg: "File '#{params['file_name']}' is empty or not in JSON format" }
      redirect "/create?bag_path=#{data_bag_name}:", 303
    end
  end

  get '/generate_bag' do
    templates_dir = MDB_CONFIG['templates_dir']
    @templates = {}
    templates_dir&.each do |tpl_name, tpl_dir|
      Dir.entries(tpl_dir).each do |tpl_file|
        next if tpl_file.match?(/^\.$/)
        next if tpl_file.match?(/^\.\./)
        begin
          JSON.parse(File.read(File.realpath("#{tpl_dir}/#{tpl_file}")))
          is_json = 0
        rescue JSON::ParserError
          is_json = 1
        end
        if is_json == 0
          @templates[tpl_name] = [] unless @templates[tpl_name].is_a? Array
          @templates[tpl_name] << tpl_file
        end
      end
    end
    if params['template']
      begin
        tpl_dir, tpl_name = params['template'].split(':')
        tpl_file = "#{MDB_CONFIG['templates_dir'][tpl_dir]}/#{tpl_name}"
        read_file = File.read(tpl_file)
        begin
          plain_data = JSON.parse(read_file)
          @error = 0
        rescue JSON::ParserError
          @error = 1
          @message = {type: 'error', msg: 'Selected template is not in JSON format' }
        end
      rescue Errno::ENOENT
        @error = 1
        @message = {type: 'error', msg: "Template #{params['tempalte']} not found" }
      end
    end
    @json_content = plain_data
    slim :generate_bag
  end

  post '/generate_bag' do
    templates_dir = MDB_CONFIG['templates_dir']
    @templates = {}
    templates_dir.each do |tpl_name, tpl_dir|
      Dir.entries(tpl_dir).each do |tpl_file|
        next if tpl_file.match?(/^\.$/)
        next if tpl_file.match?(/^\.\./)
        begin
          JSON.parse(File.read(File.realpath("#{tpl_dir}/#{tpl_file}")))
          is_json = 0
        rescue JSON::ParserError
          is_json = 1
        end
        if is_json == 0
          @templates[tpl_name] = [] unless @templates[tpl_name].is_a? Array
          @templates[tpl_name] << tpl_file
        end
      end
    end
    if params['content']
      begin
        plain_data = JSON.parse(params['content'])
        @error = 0
      rescue JSON::ParserError
        @error = 1
        session[:message] = {type: 'error', msg: 'Content field is not in JSON format' }
      end
      secret = Chef::EncryptedDataBagItem.load_secret(params['encrypted'])
    end
    @bag_content = Chef::EncryptedDataBagItem.encrypt_data_bag_item(plain_data, secret)
    @key = @all_keys.select { |_, conf| conf['path'] == params['encrypted'] }.keys.first
    @json_content = plain_data
    slim :generate_bag
  end

  get '/delete' do
    data_bag_name, file_name = params[:bag_file].split(':')
    file_path = @data_bag_dir[data_bag_name]
    bag_file = "#{file_path}/#{file_name}"
    begin
      File.delete(bag_file)
      msg = "#{file_name} has been delete."
      type = 'success'
    rescue StandardError
      msg = "An error occured to delete #{file_name}"
      type = 'error'
    end
    session[:message] = {type: type, msg: msg}
    redirect "/view?path=#{data_bag_name}:"
  end

  get '/settings' do
    @json_content = YAML.safe_load(File.read(@path_config_file))
    slim :settings
  end

  post '/settings' do
    begin
      @json_content = YAML.safe_load(params['content'])
      File.open(@path_config_file, 'w')
      File.write @path_config_file, params['content']
      session[:message] = {type: 'info', msg: 'Config file saved' }
    rescue Psych::SyntaxError
      session[:message] = {type: 'error', msg: 'YAML syntax error' }
      @json_content = YAML.safe_load(File.read(@path_config_file))
    end
    slim :settings
  end

  get '/search' do
    slim :search
  end

  post '/search' do
    @search = {}
    case_sensitive = params['case_sensitive'] == 'on'
    search_string = params['search'].strip
    if search_string.match?(/^[A-Z0-9\ -_]+$/i)
      base_path = @data_bag_dir[params['bag_path']]
      Find.find(base_path) do |file|
        next if File.directory? file

        read_file = File.open(file).read
        @error = read_file.include?('null') ? 1 : 0
        begin
          encrypted_data = JSON.parse(read_file)
        rescue JSON::ParserError
          next
        end

        bag_status = CheckEncryptedTester.new
        plain_data = encrypted_data
        encrypted = bag_status.encrypted?(encrypted_data)
        secret_keys = @all_keys.map { |_, secret| secret['path'] }
        error = nil

        if encrypted
          secret_keys.each do |secret_file|
            next unless File.exist?(secret_file)
            secret = Chef::EncryptedDataBagItem.load_secret(secret_file)
            begin
              plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash
              error = 0
            rescue StandardError
              error = 1
            end
            break if error == 0
          end
        end
        next if error == 1
        file_grep = []
        ordered_data = {'id' => plain_data.delete('id')}
        plain_data = ordered_data.merge(Hash[plain_data.sort])
        search_string = "(?i:#{search_string})" if case_sensitive
        plain_data.keys.each_with_index do |a, b|
          string_matched = ''
          matched = false
          scan_key = a.scan(/#{search_string}/)
          scan_data = plain_data[a].to_s.scan(/#{search_string}/)
          unless scan_key.empty?
            string_matched = "#{a}: "
            matched = true
          end
          unless scan_data.empty?
            string_matched = "#{a}: " + plain_data[a].to_s
            matched = true
          end
          next unless matched
          (scan_key + scan_data).uniq.each do |match_string|
            string_matched =
              string_matched.gsub(match_string, "<strong class='uk-text-primary'>#{match_string}</strong>")
          end
          file_grep << {line: b + 1, string: string_matched }
        end
        next if file_grep.empty?
        @search["#{params['bag_path']}#{file.gsub(base_path, ':')}"] = file_grep
      end
    else
      @message = {type: 'error', msg: 'Only alphanumeric search' }
    end
    slim :search
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
