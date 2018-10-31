# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

file_enc = JSON.parse(File.read('tests/data_bags/test2.json'))
secret_file = 'tests/secret_key'

describe 'Helpers' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  describe '::read_json' do
    it('test read empty json format') { expect(ReadFile.json_parse('{}')).to eq({}) }
    it('test read json format') { expect(ReadFile.json_parse('{"id": 2}')).to eq('id' => 2) }
    it('test read no json format') { expect(ReadFile.json_parse('{')).to equal(2) }
  end

  describe '::read_encrypted' do
    it('test read encrypted json') do
      expect(ReadFile.decrypt_db(file_enc, [secret_file], 'hash').first.values).to include('pink')
      expect(ReadFile.decrypt_db(file_enc, [secret_file], 'hash')[1]).to eq('tests/secret_key')
      expect(ReadFile.decrypt_db(file_enc, [secret_file], 'hash').last).to eq(0)
    end
  end
end
