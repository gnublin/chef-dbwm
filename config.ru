require 'bundler/setup'
require 'sinatra'
require 'chef/data_bag_item'

require 'tempfile'
require 'slim'

require 'sinatra/config_file'

config_file 'config.yml'

set :port, 8080
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
get '/' do
  bags_dir = {}

  if params[:path]
    # puts File.real_path(params[:path])
    puts params[:path].match?('..')
    base_path = [params[:path]]
  else
    base_path = MDB_CONFIG['data_bags_path']
  end

  base_path.each do |data_bags_dir|
    bags_dir[data_bags_dir] = {}
    Dir.entries("#{data_bags_dir}/").each do |item|
      bags_dir[data_bags_dir][item] = 'dir' if File.directory?("#{data_bags_dir}/#{item}")
      bags_dir[data_bags_dir][item] = 'file' if File.file?("#{data_bags_dir}/#{item}")
    end
  end
  @data_bags = bags_dir
  slim :index
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
      rescue
        error = 1
      end
      break if error == 0
    end
  end
  @error_type = "Private key not found to read encrypted databag #{encrypted_file}" if error == 1
  slim :read_bag
end