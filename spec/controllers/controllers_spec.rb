# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'time'
require 'json'
require 'chef_dbwm'
require 'rack/test'

DATA_BAG = '
{
  "id": "test3",
  "color": "red",
  "number": 42
}
'

describe ChefDBWM do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  describe 'Root' do
    before { get '/' }

    describe 'Root' do
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "Databags" ') { expect(last_response.body).to include('Databags') }
    end
  end

  describe 'View/Edit' do
    file_enc = 'tests/data_bags/test2.json'
    file_raw = 'tests/data_bags/test1.json'
    describe '::View' do
      before { get '/view', **params }
      describe '::with parameters' do
        let(:params) { {path: 'tests/data_bags/'} }
        it('returns 200 OK') { expect(last_response).to be_ok }
        it('contain "Databags"') { expect(last_response.body).to include('Databags') }
        it('contain "test1.json"') { expect(last_response.body).to include('test1.json') }
        it('contain "test2.json"') { expect(last_response.body).to include('test2.json') }
        it('doesn\'t contain "test3.json"') { expect(last_response.body).not_to include('test3.json') }
      end
    end
    describe '::Edit' do
      before { get '/edit', **params }
      describe '::view' do
        let(:params) { {bag_file: file_enc} }
        it('returns 200 OK') { expect(last_response).to be_ok }
        it('contain "EDIT"') { expect(last_response.body).to include('>edit<') }
        it('Submit button is disabled') { expect(last_response.body).to include('disabled') }
      end
      describe '::edit' do
        let(:params) { {bag_file: file_enc, disable: false} }
        it('returns 200 OK') { expect(last_response).to be_ok }
        it('not contain "EDIT"') { expect(last_response.body).not_to include('>edit<') }
        it('Submit button is enabled') { expect(last_response.body).not_to include('disabled') }
      end
      describe '::update' do
        let(:params) { {bag_file: file_enc, disable: false} }
        it('returns 200 OK') { expect(last_response).to be_ok }
        it('not contain "EDIT"') { expect(last_response.body).not_to include('>edit<') }
        it('Submit button is enabled') { expect(last_response.body).not_to include('disabled') }
      end
    end
    describe '::Update' do
      before { post '/edit', **params }
      describe '::Encrypted' do
        let(:params) do
          {
            bag_file: file_enc,
            content: '{
              "id": "test2",
              "color": "pink",
              "number": 42
            }',
            format: 'json',
            file_name: 'test3',
            encrypted: true,
            secret_key: 'tests/secret_key'
          }
        end
        it('returns redirect') { expect(last_response).to be_redirect }
        it('file test2.json new encrypted color hash') do
          expect(File.read(file_enc)).not_to include('RjGUHZIoIUr4qoDsIyx8g4nagspfgw==')
        end
        it('file test2.json no modify encrypted number') do
          expect(File.read(file_enc)).to include('/oDVL+22UMbRBygxGpFdiAcCaQ==')
        end
        it('file test2.json contain id') { expect(File.read(file_enc)).to include('"id": "test2"') }
      end
      describe '::Raw' do
        let(:params) do
          {
            bag_file: file_raw,
            content: '{
              "id": "test1",
              "color": "pink",
              "number": 73
            }',
            format: 'json',
            file_name: 'test1',
            encrypted: false,
          }
        end
        it('returns redirect') { expect(last_response).to be_redirect }
        it('file test1.json new encrypted color') { expect(File.read(file_raw)).not_to include('black') }
        it('file test1.json no modify number') { expect(File.read(file_raw)).to include('73') }
        it('file test1.json contain id') { expect(File.read(file_raw)).to include('"id": "test1"') }
      end
    end
  end

  describe 'Create/Delete' do
    file = 'tests/data_bags/test3.json'

    describe '::create' do
      before { post '/create', **params }
      let(:params) do
        {
          bag_path: 'tests/data_bags',
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

    describe '::delete' do
      before { get '/delete', **params }
      let(:params) do
        {
          bag_file: 'tests/data_bags/test3.json',
        }
      end
      it('returns redirect') { expect(last_response).to be_redirect }
      it('test3.json has been deleted') { expect(File).not_to exist(file) }
    end
  end
end
