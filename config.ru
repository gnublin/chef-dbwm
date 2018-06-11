require 'bundler/setup'
require 'sinatra'
require 'chef/data_bag_item'

require 'tempfile'
require 'slim'

require 'sinatra/config_file'

config_file 'config.yml'

# TODO: make node_modules in subfolder to co-work with font awesome (see if font awesome npm possible)
# TODO: edit_bag for view
# TODO: Make disable form by JS

set :root, File.dirname(__FILE__)
set :port, 8080
set :slim, layout: :_layout
set :public_folder, File.dirname(__FILE__) + '/node_modules'

MDB_CONFIG = settings.mdb_config
puts MDB_CONFIG
use Rack::Logger

helpers do
  def logger
    request.logger
  end
end
Bundler.require

class CheckEncryptedTester
  include Chef::EncryptedDataBagItem::CheckEncrypted
end

# run Mdb
before do
  @data_bag_dir = MDB_CONFIG['data_bags_path']
end

get '/' do
  slim :index
end

get '/view' do
  bags_dir = {}

  if params[:path]
    real_path = File.realpath(params[:path])
    check_path = MDB_CONFIG['data_bags_path'].map { |databag| real_path.match?(File.realpath(databag['path'])) }
    base_path = real_path if check_path.include? true

    base_path = File.realpath(base_path)
    bags_dir[base_path] = {}
    root_dir = MDB_CONFIG['data_bags_path'].map { |databag| base_path == File.realpath(databag['path']) }
    Dir.entries("#{base_path}/").each do |item|
      next if item.match?(/^\.$/)
      next if item.match?(/^\.\./) && base_path == MDB_CONFIG['data_bags_path']
      next if item.match?(/^\.\./) && root_dir.include?(true)
      bags_dir[base_path][item] = 'dir' if File.directory?("#{base_path}/#{item}")
      bags_dir[base_path][item] = 'file' if File.file?("#{base_path}/#{item}")
    end
    @data_bags = bags_dir
  else
    @error_message = 'Please specify a good databag'
  end
  slim :view
end

get '/read_databag' do
  encrypted_file = params[:bag_file]
  encrypted_data = JSON.parse(File.read(encrypted_file))
  bag_status = CheckEncryptedTester.new
  @plain_data = encrypted_data
  @encrypted = bag_status.encrypted?(encrypted_data)
  error = 0
  if @encrypted
    MDB_CONFIG['secret_keys_path'].each do |secret_file|
      next unless File.exist?(secret_file)
      secret = Chef::EncryptedDataBagItem.load_secret(secret_file)
      begin
        @plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash
        error = 0
      rescue StandardError
        error = 1
      end
      break if error == 0
    end
  end
  @error_type = "Private key not found to read encrypted databag #{encrypted_file}" if error == 1
  slim :read_bag
end

get '/edit' do
  encrypted_file = params[:bag_file]
  encrypted_data = JSON.parse(File.read(encrypted_file))
  bag_status = CheckEncryptedTester.new
  @plain_data = encrypted_data
  @encrypted = bag_status.encrypted?(encrypted_data)
  error = 0
  @secret_file_used = ''
  if @encrypted
    MDB_CONFIG['secret_keys_path'].each do |secret_file|
      next unless File.exist?(secret_file)
      secret = Chef::EncryptedDataBagItem.load_secret(secret_file)
      begin
        @plain_data = Chef::EncryptedDataBagItem.new(encrypted_data, secret).to_hash
        error = 0
      rescue StandardError
        error = 1
      end
      @secret_file_used = secret_file
      break if error == 0
    end
  end
  @error_type = "Private key not found to read encrypted databag #{encrypted_file}" if error == 1
  slim :edit_bag
end

post '/edit' do
  file_params = {}
  params.select { |param| param.match(/#{params['__id']}/) }.map do |param, val|
    file_params[param.gsub(/#{params['__id']}_/, '')] = val
  end
  p file_params.to_json
  if params['encrypted']
    secret = Chef::EncryptedDataBagItem.load_secret(params['secret_key'])
    file_params = Chef::EncryptedDataBagItem.encrypt_data_bag_item(file_params, secret)
  end

  encrypted_file = params['bag_file']
  File.open(encrypted_file, 'w')
  File.write encrypted_file, JSON.pretty_generate(file_params)

  redirect "/edit?bag_file=#{params['bag_file']}"
end
