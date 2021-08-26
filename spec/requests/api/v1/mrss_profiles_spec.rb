# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::MrssProfiles do
  before do
    MrssProfile.delete_all
    MrssProfile.refresh_index!
  end

  describe 'GET /api/v1/mrss_profiles' do
    context 'when profiles exist' do
      before do
        MrssProfile.create(id: 'http://some.mrss.url/feed2.xml')
        MrssProfile.create(id: 'http://some.mrss.url/feed1.xml')
        MrssProfile.refresh_index!
      end

      it 'returns an array of indexed MRSS profiles ordered by name' do
        get '/api/v1/mrss_profiles'
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body).first).to match(hash_including('id' => 'http://some.mrss.url/feed2.xml'))
        expect(JSON.parse(response.body).last).to match(hash_including('id' => 'http://some.mrss.url/feed1.xml'))
      end
    end
  end

  describe 'POST /api/v1/mrss_profiles' do
    context 'when MRSS feed URL does not already exist in index' do
      before do
        post '/api/v1/mrss_profiles', params: { url: 'http://some.mrss.url/feed2.xml' }
      end

      it 'creates a MRSS profile' do
        expect(MrssProfile.find('http://some.mrss.url/feed2.xml')).to be_present
      end

      it 'enqueues the importer to download and index photos' do
        expect(MrssPhotosImporter).to have_enqueued_sidekiq_job(MrssProfile.all.last.name)
      end

      it 'returns created profile as JSON' do
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to match(hash_including('id' => 'http://some.mrss.url/feed2.xml', 'name' => an_instance_of(String)))
      end
    end

    context 'when MRSS feed URL already exists in index' do
      before do
        @mrss_profile = MrssProfile.create(id: 'http://some.mrss.url/already.xml')
        post '/api/v1/mrss_profiles', params: { url: 'http://some.mrss.url/already.xml' }
      end

      it 'returns existing profile as JSON' do
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to match(hash_including('id' => 'http://some.mrss.url/already.xml',
                                                                  'name' => @mrss_profile.name))
      end
    end
  end
end
