# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

SEARCH_ENC = '42'
SEARCH_RAW = '73'

describe 'search' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  describe '::display' do
    before { get '/search', **params }
    describe '::no_parameters' do
      let(:params) { {bag_path: 'none'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
    end
    describe '::with_parameters' do
      let(:params) { {bag_path: 'main'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain main') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
  end

  describe '::search' do
    before { post '/search', **params }
    describe '::with_parameters_enc' do
      let(:params) { {bag_path: 'main', search: SEARCH_ENC} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain test2.json') { expect(last_response.body).to include('main:/test2.json') }
      it('contain 42') { expect(last_response.body).to include('42</strong>') }
      it('main selected') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
    describe '::with_parameters_raw' do
      let(:params) { {bag_path: 'main', search: SEARCH_RAW} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain test1.json') { expect(last_response.body).to include('main:/test1.json') }
      it('contain 73') { expect(last_response.body).to include('73</strong>') }
      it('main selected') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
  end
end
