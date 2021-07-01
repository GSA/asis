# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
require 'rails_helper'

describe Api::V1::InstagramProfiles do
  describe 'GET /api/v1/instagram_profiles' do
    context 'when profiles exist' do
      before do
        InstagramProfile.delete_all
        InstagramProfile.create(username: 'profile2', id: '2')
        InstagramProfile.create(username: 'profile1', id: '1')
        InstagramProfile.refresh_index!
      end

      it 'returns an array of indexed Instagram profiles' do
        get '/api/v1/instagram_profiles'
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body).first).to match(hash_including('username' => 'profile1', 'id' => '1'))
        expect(JSON.parse(response.body).last).to match(hash_including('username' => 'profile2', 'id' => '2'))
      end
    end
  end

  describe 'POST /api/v1/instagram_profiles' do
    before do
      post '/api/v1/instagram_profiles', params: { id: '192237852', username: 'bureau_of_reclamation' }
      InstagramProfile.refresh_index!
    end

    it 'creates a Instagram profile' do
      expect(InstagramProfile.find('192237852')).to be_present
    end

    it 'enqueues the importer to download and index photos' do
      expect(InstagramPhotosImporter).to have_enqueued_sidekiq_job('192237852')
    end

    it 'returns created profile as JSON' do
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)).to match(hash_including('username' => 'bureau_of_reclamation', 'id' => '192237852'))
    end
  end
end
