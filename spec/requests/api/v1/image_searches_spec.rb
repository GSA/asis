# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ImageSearches do
  describe 'GET /api/v1/image_searches' do
    context 'when all params passed in' do
      let(:image_search) { double(ImageSearch) }
      let(:search_results) { Hashie::Mash.new('total' => 1, 'offset' => 0, 'results' => [{ 'type' => 'MrssPhoto', 'title' => 'title', 'url' => 'https://www.flickr.com/photos/41555360@N03/14610842557/', 'thumbnail_url' => 'https://farm4.staticflickr.com/3841/14610842557_ed0ff5879a_q.jpg', 'taken_at' => '2013-09-20' }], 'suggestion' => { 'text' => 'cindy', 'highlighted' => '<strong>cindy</strong>' }) }
      let(:params) do
        { query: 'some query', size: 11, from: 10, flickr_groups: 'fg1,fg2', flickr_users: 'fu1,fu2', mrss_names: '4,9' }
      end

      before do
        expect(ImageSearch).to receive(:new).with('some query', size: 11, from: 10, flickr_groups: %w[fg1 fg2], flickr_users: %w[fu1 fu2], mrss_names: %w[4 9]).and_return(image_search)
      end

      it 'performs the search with the appropriate params' do
        expect(image_search).to receive(:search) { search_results }
        get '/api/v1/image', params: params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to match(hash_including('total' => 1, 'offset' => 0, 'results' => [{ 'type' => 'MrssPhoto', 'title' => 'title', 'url' => 'https://www.flickr.com/photos/41555360@N03/14610842557/', 'thumbnail_url' => 'https://farm4.staticflickr.com/3841/14610842557_ed0ff5879a_q.jpg', 'taken_at' => '2013-09-20' }], 'suggestion' => { 'text' => 'cindy', 'highlighted' => '<strong>cindy</strong>' }))
      end
    end

    context 'when an exception is raised' do
      let(:params) { { query: 'some query' } }

      it 'logs the error' do
        expect(ImageSearch).to receive(:new).and_raise
        expect(Rails.logger).to receive(:error)
        get '/api/v1/image', params: params
      end

      it 'returns 500 error' do
        get '/api/v1/image', params: params
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
