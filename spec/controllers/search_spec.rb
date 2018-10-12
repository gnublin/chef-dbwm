# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

SEARCH_ENC = '42'
SEARCH_RAW = '73'
SEARCH_ERR = '73{'
SEARCH_TO_STRIP = ' 73'
SEARCH_WITH_SPACE = 'orange black'

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
    describe '::with_parameters_err' do
      let(:params) { {bag_path: 'main', search: SEARCH_ERR} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('no contain test1.json') { expect(last_response.body).not_to include('main:/test1.json') }
      it('no contain 73') { expect(last_response.body).not_to include('73</strong>') }
      it('contain err') { expect(last_response.body).to include('Only alphanumeric search') }
      it('main selected') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
    describe '::with_parameters_to_strip' do
      let(:params) { {bag_path: 'main', search: SEARCH_TO_STRIP} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain test1.json') { expect(last_response.body).to include('main:/test1.json') }
      it('contain 73 without space') { expect(last_response.body).to include('>73</strong>') }
      it('main selected') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
    describe '::with_parameters_with_space' do
      let(:params) { {bag_path: 'main', search: SEARCH_WITH_SPACE} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain test42.json') { expect(last_response.body).to include('main:/test42.json') }
      it('contain orange black') { expect(last_response.body).to include('>orange black</strong>') }
      it('contain other_color') { expect(last_response.body).to include('other_color') }
      it('main selected') { expect(last_response.body).to include('<option selected="selected" value="main">main') }
    end
  end
end
