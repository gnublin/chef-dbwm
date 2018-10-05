# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

origin_settings = '---
  mdb_config:
    secret_keys_path:
      main:
        path: tests/secret_key
    data_bags_path:
      main: tests/data_bags
    templates_dir:
      dir1: tests/templates
'

modif_settings = '---
  mdb_config:
    secret_keys_path:
      main:
        path: tests/secret_key
    data_bags_path:
      main: tests/data_bags
    templates_dir:
      dir2: tests/templates
'

describe 'Settings' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }
  describe 'Get' do
    describe ':settings' do
      before { get '/settings' }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "---"') { expect(last_response.body).to include('---') }
      it('returns "secret_keys_path"') { expect(last_response.body).to include('secret_keys_path') }
    end
  end

  describe 'Post' do
    before { post '/settings', **params }
    describe '::change_settings_test' do
      let(:params) { { content: modif_settings } }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "dir2" ') { expect(last_response.body).to include('dir2') }
      it('not contain "dir1" ') { expect(last_response.body).not_to include('dir1') }
      it('contain "---"') { expect(last_response.body).to include('---') }
      it('returns "secret_keys_path"') { expect(last_response.body).to include('secret_keys_path') }
    end
    describe '::change_settings_origin_test' do
      let(:params) { { content: origin_settings } }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "dir1" ') { expect(last_response.body).to include('dir1') }
      it('not contain "dir2" ') { expect(last_response.body).not_to include('dir2') }
      it('contain "---"') { expect(last_response.body).to include('---') }
      it('returns "secret_keys_path"') { expect(last_response.body).to include('secret_keys_path') }
    end
  end
end
