# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

class CheckEncryptedTester
  include Chef::EncryptedDataBagItem::CheckEncrypted
end

class ReadFile
  def self.json_parse(content)
    json_content = JSON.parse(content)
    json_content.nil? ? 2 : json_content
  rescue JSON::ParserError
    2
  end

  def self.decrypt_db(data_plain, secrets_file, type)
    data = ''
    the_secret = ''
    error = 0
    secrets_file.each do |secret_file|
      next unless File.exist?(secret_file)
      secret = Chef::EncryptedDataBagItem.load_secret(secret_file)
      begin
        data =
          if type == 'hash'
            Chef::EncryptedDataBagItem.new(data_plain, secret).to_hash
          else
            Chef::EncryptedDataBagItem.new(data_plain, secret)
          end
        error = 0
      rescue StandardError
        error = 1
      end
      the_secret = secret_file
      break if error == 0
    end
    [data, the_secret, error]
  end
end
