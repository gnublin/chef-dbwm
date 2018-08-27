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
  end
end
