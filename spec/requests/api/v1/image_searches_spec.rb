# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ImageSearches do
  describe 'GET /api/v1/image_searches' do
    context 'when all params passed in' do
      let(:image_search) { double(ImageSearch) }
      let(:search_results) { Hashie::Mash.new('total' => 1, 'offset' => 0, 'results' => [{ 'type' => 'InstagramPhoto', 'title' => 'title', 'url' => 'http://instagram.com/p/efykKOIaCh/', 'thumbnail_url' => 'http://scontent-b.cdninstagram.com/hphotos-xpf1/outbound-distilleryimage9/t0.0-17/OBPTH/9c929416223811e3bad522000ab5bccf_5.jpg', 'taken_at' => '2013-09-20' }], 'suggestion' => { 'text' => 'cindy', 'highlighted' => '<strong>cindy</strong>' }) }
      let(:params) do
        { query: 'some query', size: 11, from: 10, flickr_groups: 'fg1,fg2', flickr_users: 'fu1,fu2', instagram_profiles: 'ip1', mrss_names: '4,9' }
      end
      before do
        expect(ImageSearch).to receive(:new).with('some query', size: 11, from: 10, flickr_groups: %w[fg1 fg2], flickr_users: %w[fu1 fu2], instagram_profiles: ['ip1'], mrss_names: %w[4 9]).and_return(image_search)
      end

      it 'performs the search with the appropriate params' do
        expect(image_search).to receive(:search) { search_results }
        get '/api/v1/image', params: params
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to match(hash_including('total' => 1, 'offset' => 0, 'results' => [{ 'type' => 'InstagramPhoto', 'title' => 'title', 'url' => 'http://instagram.com/p/efykKOIaCh/', 'thumbnail_url' => 'http://scontent-b.cdninstagram.com/hphotos-xpf1/outbound-distilleryimage9/t0.0-17/OBPTH/9c929416223811e3bad522000ab5bccf_5.jpg', 'taken_at' => '2013-09-20' }], 'suggestion' => { 'text' => 'cindy', 'highlighted' => '<strong>cindy</strong>' }))
      end
    end

    context 'when an exception is raised' do
      let(:params) { { query: 'some query' } }
      before do
        expect(ImageSearch).to receive(:new).and_raise
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error)
        get '/api/v1/image', params: params
      end

      it 'attempts to report the error to Airbrake' do
        expect(Airbrake).to receive(:notify)
        get '/api/v1/image', params: params
      end

      it 'returns 500 error' do
        get '/api/v1/image', params: params
        expect(response.status).to eq(500)
      end
    end
  end
end
