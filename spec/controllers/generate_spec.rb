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
}
'
tpl_file_1 = 'dir1:num1.json'
tpl_file_2 = 'dir1:num2.json'
tpl_file_3 = 'dir1:num3.json'

describe ChefDBWM do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  describe 'Generate post' do
    before { post '/generate_bag', **params }
    let(:params) do
      {
        content: BAG1,
        encrypted: 'tests/secret_key'
      }
    end
    it('returns 200 OK') { expect(last_response).to be_ok }
    it('contain "Encrypted check1" ') { expect(last_response.body).to include('auth_tag') }
    it('contain "Encrypted check2" ') { expect(last_response.body).to include('aes-256-gcm') }
    it('contain "Encrypted check3" ') { expect(last_response.body).to include('version&quot;: 3') }
    it('contain "Encrypted with key name" ') { expect(last_response.body).to include('Encrypted data with main key') }
  end

  describe 'Generate get' do
    before { get '/generate_bag' }
    it('returns 200 OK') { expect(last_response).to be_ok }
    it('contain default bag') { expect(last_response.body).to include('&quot;id&quot;: &quot;ressource_id&quot;') }
    it('contain key list') { expect(last_response.body).to include('option value="tests/secret_key') }
    it('contain tpl num1') { expect(last_response.body).to include("option value=\"#{tpl_file_1}\"") }
    it('contain tpl num2') { expect(last_response.body).to include("option value=\"#{tpl_file_2}\"") }
    it('not contain tpl num3') { expect(last_response.body).not_to include(tpl_file_3) }
  end

  describe 'Generate get templates' do
    before { get '/generate_bag', **params }
    describe '::tpl1' do
      let(:params) do
        {
          template: tpl_file_1
        }
      end
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain tpl1 num1') { expect(last_response.body).to include('&quot;id&quot;: &quot;num1&quot;') }
      it('contain tpl1 login') { expect(last_response.body).to include('&quot;login&quot;: &quot;TO_REPLACE&quot;') }
    end
    describe '::tpl2' do
      let(:params) do
        {
          template: tpl_file_2
        }
      end
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain tpl2 num1') { expect(last_response.body).to include('&quot;id&quot;: &quot;num2&quot;') }
      it('contain tpl2 token') { expect(last_response.body).to include('&quot;token&quot;: &quot;TO_REPLACE&quot;') }
    end
    describe '::tpl3' do
      let(:params) do
        {
          template: tpl_file_3
        }
      end
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain tpl3 error msg') do
        expect(last_response.body).to include('Selected template is not in JSON format')
      end
    end
  end
end
