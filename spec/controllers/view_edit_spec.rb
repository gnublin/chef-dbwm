# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

BAG1 = '
{
  "id": "test3",
  "color": "bleu",
  "number": 73
}'

describe 'View/Edit' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  file_enc = 'main:test2.json'
  file_enc_path = 'tests/data_bags/test2.json'
  file_wrong_enc = 'main:test4.json'
  file_wrong_format = 'main:test5.json'
  file_raw = 'main:test1.json'
  file_raw_path = 'tests/data_bags/test1.json'
  file_not_exist = 'main:test4242.json'
  describe '::View' do
    before { get '/view?path=main', **params }
    describe '::with parameters' do
      let(:params) { {path: 'main'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "DataBags"') { expect(last_response.body).to include('DataBags') }
      it('contain "test1.json"') { expect(last_response.body).to include('test1.json') }
      it('contain "test2.json"') { expect(last_response.body).to include('test2.json') }
      it('doesn\'t contain "test3.json"') { expect(last_response.body).not_to include('test3.json') }
      it('doesn\'t contain HomePage"') { expect(last_response.body).not_to include('HomePage') }
    end
    describe '::with parameters::sub' do
      let(:params) { {path: 'main:/sub'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "DataBags"') { expect(last_response.body).to include('DataBags') }
      it('contain "sub.json"') { expect(last_response.body).to include('sub.json') }
      it('doesn\'t contain "test3.json"') { expect(last_response.body).not_to include('test3.json') }
      it('doesn\'t contain HomePage"') { expect(last_response.body).not_to include('HomePage') }
    end
    describe '::with parameters::tweak_path' do
      let(:params) { {path: 'main:../'} }
      it('returns 301 OK') { expect(last_response).to be_redirect }
      it('doesn\'t contain "test1.json"') { expect(last_response.body).not_to include('test1.json') }
      it('contain HomePage') { expect(last_response.body).not_to include('HomePage') }
    end
    describe '::with parameters::wrong path' do
      let(:params) { {path: 'main:/test/dsq42'} }
      it('returns redirect to 404') { expect(last_response).to be_redirect }
    end
  end
  describe '::Edit' do
    before { get '/edit', **params }
    describe '::display' do
      let(:params) { {bag_file: file_enc} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "EDIT"') { expect(last_response.body).to include('>edit<') }
      it('contain "VIEW"') { expect(last_response.body).to include('>view<') }
      it('Submit button is disabled') { expect(last_response.body).to include('disabled') }
    end
    describe '::edit::wrong::key' do
      let(:params) { {bag_file: file_wrong_enc} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('not contain an error msg') do
        expect(last_response.body).to include('Private key not found to read encrypted data bag')
      end
    end
    describe '::edit::wrong::format' do
      let(:params) { {bag_file: file_wrong_format} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain an error msg') { expect(last_response.body).to include('is not in JSON format') }
    end
    describe '::edit::file::not_found' do
      let(:params) { {bag_file: file_not_exist} }
      it('returns redirect to 404') { expect(last_response).to be_redirect }
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
        expect(File.read(file_enc_path)).not_to include('RjGUHZIoIUr4qoDsIyx8g4nagspfgw==')
      end
      it('file test2.json no modify encrypted number') do
        expect(File.read(file_enc_path)).to include('o+aI9uVaNUfiH7EWW335Hdkz/A==')
      end
      it('file test2.json contain id') { expect(File.read(file_enc_path)).to include('"id": "test2"') }
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
      it('file test1.json new encrypted color') { expect(File.read(file_raw_path)).not_to include('black') }
      it('file test1.json no modify number') { expect(File.read(file_raw_path)).to include('73') }
      it('file test1.json contain id') { expect(File.read(file_raw_path)).to include('"id": "test1"') }
    end
  end
end
