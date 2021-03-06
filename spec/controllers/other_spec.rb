# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

require 'spec_helper'
require 'chef_dbwm'
require 'rack/test'

describe 'Other' do
  include Rack::Test::Methods
  let(:app) { ChefDBWM }

  describe 'Error' do
    describe '::404' do
      before { get '/toto' }
      it('returns 404') { expect(last_response.status).to eq(404) }
    end
  end

  describe 'Root' do
    before { get '/' }
    describe 'Root' do
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "DataBags" ') { expect(last_response.body).to include('DataBags') }
      it('contain "Generate" ') { expect(last_response.body).to include('Generate') }
      it('contain "Search" ') { expect(last_response.body).to include('Search') }
      it('contain "Settings" ') { expect(last_response.body).to include('Settings') }
      it('contain "Github" ') { expect(last_response.body).to include('On Github project') }
      it('contain "github class" ') { expect(last_response.body).to include('class="fab fa-github') }
      it('contain "Open issue" ') { expect(last_response.body).to include('target="_blank">Open issue</a>') }
      it('contain "LICENSE" ') { expect(last_response.body).to include('LICENSE" target="_blank">MIT License</a>') }
    end
  end

  describe 'View button' do
    before { get '/view', **params }
    describe 'Main' do
      let(:params) { {path: 'main:/'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "DataBags" ') { expect(last_response.body).to include('DataBags') }
      it('contain "Generate" ') { expect(last_response.body).to include('Generate') }
      it('contain "Search" ') { expect(last_response.body).to include('Search') }
      it('contain "Settings" ') { expect(last_response.body).to include('Settings') }
      it('contain "Github" ') { expect(last_response.body).to include('On Github project') }
      it('contain "github class" ') { expect(last_response.body).to include('class="fab fa-github') }
      it('contain "Open issue" ') { expect(last_response.body).to include('target="_blank">Open issue</a>') }
      it('contain "LICENSE" ') { expect(last_response.body).to include('LICENSE" target="_blank">MIT License</a>') }
      it('contain "Create"') { expect(last_response.body).to include('Create') }
      it('contain "Create dir"') { expect(last_response.body).to include('Create dir') }
      it('contain "Delete dir"') { expect(last_response.body).not_to include('Delete dir') }
    end
  end
  describe 'Sub view button' do
    before { get '/view', **params }
    describe 'Main' do
      let(:params) { {path: 'main:/sub'} }
      it('returns 200 OK') { expect(last_response).to be_ok }
      it('contain "Create"') { expect(last_response.body).to include('Create') }
      it('contain "Create dir"') { expect(last_response.body).to include('Create dir') }
      it('contain "Delete dir"') { expect(last_response.body).to include('Delete dir') }
    end
  end
end
