require 'bundler/setup'
require 'sinatra'
require 'chef/data_bag_item'

require 'tempfile'
require 'slim'

require 'sinatra/config_file'
require 'pry'
require 'hashdiff'

config_file 'config.yml'

set :root, File.dirname(__FILE__)
set :port, 8080
set :slim, layout: :_layout
set :public_folder, File.dirname(__FILE__) + '/node_modules'

MDB_CONFIG = settings.mdb_config
puts MDB_CONFIG
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
# run Mdb
before do
  @data_bag_dir = MDB_CONFIG['data_bags_path']
  @message = session.delete(:message)
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

get '/edit' do
  secret_keys = MDB_CONFIG['secret_keys_path'].map { |_, secret| secret['path'] }
  @format = 'form'
  encrypted_file = params[:bag_file]
  read_file = File.read(encrypted_file)
  encrypted_data = JSON.parse(read_file)
  bag_status = CheckEncryptedTester.new
  @plain_data = encrypted_data
  @encrypted = bag_status.encrypted?(encrypted_data)
  error = 0
  @secret_file_used = ''
  if @encrypted
    secret_keys.each do |secret_file|
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
  type = @plain_data.map { |_, val| val.class }
  msg = type.include?(Hash) ? 'json' : 'form'
  msg = 'json' if @plain_data.empty?
  @format = msg
  @message = {type: 'info', msg: "Default edition format is #{msg}" } if @message.nil?
  @error_type = "Private key not found to read encrypted databag #{encrypted_file}" if error == 1
  slim :edit_bag
end

post '/edit' do
  bag_new_data = {}
  if params['format'] == 'json'
    bag_new_data = JSON.parse(params['content'])
  else
    params.select { |param| param.match(/#{params['__id']}/) }.map do |param, val|
      bag_new_data[param.gsub(/#{params['__id']}_/, '')] = val
    end
  end
  bag_file = params['bag_file']
  bag_origin_data = JSON.parse(File.read(bag_file))

  if params['encrypted'] == 'true'
    secret = Chef::EncryptedDataBagItem.load_secret(params['secret_key'])
    bag_origin_data = Chef::EncryptedDataBagItem.new(bag_origin_data, secret).to_hash
  end
  diff_get = HashDiff.diff(bag_origin_data, bag_new_data)
  diff_patch = HashDiff.patch!({}, diff_get)

  if params['encrypted'] == 'true'
    secret = Chef::EncryptedDataBagItem.load_secret(params['secret_key'])
    bag_new_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(diff_patch, secret)
  end

  bag_new_data = bag_origin_data.merge(bag_new_data)
  File.open(bag_file, 'w')
  File.write bag_file, "#{JSON.pretty_generate(bag_new_data)}\n"

  redirect "/edit?bag_file=#{params['bag_file']}"
end

get '/create' do
  @all_keys = MDB_CONFIG['secret_keys_path']
  slim :create_bag
end

post '/create' do
  bag_file = "#{params['bag_path']}/#{params['file_name']}.json"
  data = JSON.parse(params['content'])
  unless params['encrypted'] == 'raw'
    secret = Chef::EncryptedDataBagItem.load_secret(params['encrypted'])
    data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
  end
  File.open(bag_file, 'w')
  File.write bag_file, "#{JSON.pretty_generate(data)}\n"
  session[:message] = {type: 'success', msg: "#{params['file_name']}.json has been created successfully" }
  redirect "/edit?bag_file=#{bag_file}"
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

get '/*' do
  slim :index
end
