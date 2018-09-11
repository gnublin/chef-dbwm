# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

DATA_BAG = '
{
  "id": "test3",
  "color": "red",
  "number": 42
}
'

describe 'Create/Delete' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  file = 'tests/data_bags/test3.json'

  describe '::create' do
    before { post '/create', **params }
    describe '::create::valid' do
      let(:params) do
        {
          bag_path: 'main:',
          file_name: 'test3',
          encrypted: 'tests/secret_key',
          content: DATA_BAG,
        }
      end
      it('returns redirect') { expect(last_response).to be_redirect }
      it('create a test3.json file') { expect(File).to exist(file) }
      it('file test3.json contain id') { expect(File.read(file)).to include('"id": "test') }
      it('file test3.json contain encrypt_data') { expect(File.read(file)).to include('"encrypted_data"') }
      it('file test3.json contain cipher') { expect(File.read(file)).to include('"cipher": "aes-256-gcm"') }
      it('file test3.json is Hash class') { expect(JSON.parse(File.read(file))).to be_a(Hash) }
    end
    describe '::create::invalid_json::plain' do
      let(:params) do
        {
          bag_path: 'main:',
          file_name: 'test6',
          encrypted: 'raw',
          content: '{"test": fail',
        }
      end
      it('returns redirect') { expect(last_response.status).to eq(303) }
    end
    describe '::create::invalid_json::encrypted' do
      let(:params) do
        {
          bag_path: 'main:',
          file_name: 'test6',
          encrypted: 'tests/secret_key',
          content: '{"test": fail',
        }
      end
      it('returns redirect') { expect(last_response.status).to eq(303) }
    end
  end

  describe '::delete' do
    before { get '/delete', **params }
    let(:params) do
      {
        bag_file: 'main:test3.json',
      }
    end
    it('returns redirect') { expect(last_response).to be_redirect }
    it('test3.json has been deleted') { expect(File).not_to exist(file) }
  end
end
