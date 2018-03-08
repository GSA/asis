# frozen_string_literal: true

require 'rails_helper'

describe InstagramPhotosImporter do
  it { is_expected.to be_retryable true }
  it { is_expected.to be_unique }

  describe '#perform' do
    before do
      InstagramPhoto.delete_all
      InstagramPhoto.refresh_index!
    end

    let(:importer) { InstagramPhotosImporter.new }
    let(:instagram_client) { double('Instagram client') }

    context 'when days_ago is specified' do
      it 'should convert that to a timestamp and use it when fetching the recent media' do
        expect_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', min_timestamp: a_value_within(10).of(7.days.ago.to_i))
        importer.perform('1234', 7)
      end
    end

    context 'when days_ago is not specified' do
      it 'should fetch the recent media' do
        expect_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', {})
        importer.perform('1234')
      end
    end

    context 'when photos are returned' do
      before do
        photo1 = Hashie::Mash.new(id: '123456',
                                  user: { username: 'user1' },
                                  tags: %w[tag1 tag2],
                                  caption: { text: 'first photo' },
                                  created_time: '1404920005',
                                  likes: { count: 3000 },
                                  comments: { count: 300 },
                                  link: 'http://photo1',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail1'
                                  } })
        photo2 = Hashie::Mash.new(id: '7890',
                                  user: { username: 'user2' },
                                  tags: %w[other stuff],
                                  caption: { text: 'second photo' },
                                  created_time: '1406008375',
                                  likes: { count: 2000 },
                                  comments: { count: 200 },
                                  link: 'http://photo2',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail2'
                                  } })
        batch1_photos = [photo1, photo2]
        photo3 = Hashie::Mash.new(id: '7809',
                                  user: { username: 'user2' },
                                  tags: %w[other stuff],
                                  caption: { text: 'third photo' },
                                  created_time: '1406008374',
                                  likes: { count: 1999 },
                                  comments: { count: 199 },
                                  link: 'http://photo3',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail3'
                                  } })
        photo4 = Hashie::Mash.new(id: '7808',
                                  user: { username: 'user2' },
                                  tags: %w[other stuff],
                                  caption: { text: 'fourth photo' },
                                  created_time: '1406008373',
                                  likes: { count: 1998 },
                                  comments: { count: 198 },
                                  link: 'http://photo4',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail4'
                                  } })
        batch2_photos = [photo3, photo4]
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', {}) { batch1_photos }
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', max_id: '7890') { batch2_photos }
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', max_id: '7808') { [] }
      end

      it 'should store and index them' do
        importer.perform('1234')
        first = InstagramPhoto.find('123456')
        expect(first.id).to eq('123456')
        expect(first.username).to eq('user1')
        expect(first.tags).to eq(%w[tag1 tag2])
        expect(first.caption).to eq('first photo')
        expect(first.taken_at).to eq(Date.parse('2014-07-09'))
        expect(first.popularity).to eq(3300)
        expect(first.url).to eq('http://photo1')
        expect(first.thumbnail_url).to eq('http://photo_thumbnail1')
        second = InstagramPhoto.find('7890')
        expect(second.id).to eq('7890')
        expect(second.username).to eq('user2')
        expect(second.tags).to eq(%w[other stuff])
        expect(second.caption).to eq('second photo')
        expect(second.taken_at).to eq(Date.parse('2014-07-22'))
        expect(second.popularity).to eq(2200)
        expect(second.url).to eq('http://photo2')
        expect(second.thumbnail_url).to eq('http://photo_thumbnail2')
      end
    end

    context 'when photo cannot be created' do
      let(:photos) do
        photo1 = Hashie::Mash.new(id: '123456',
                                  user: { username: 'user1' },
                                  tags: %w[tag1 tag2],
                                  caption: 'this will break it',
                                  created_time: '1404920005',
                                  likes: { count: 3000 },
                                  comments: { count: 300 },
                                  link: 'http://photo1',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail1'
                                  } })
        photo2 = Hashie::Mash.new(id: '7890',
                                  user: { username: 'user2' },
                                  tags: %w[other stuff],
                                  caption: { text: 'second photo' },
                                  created_time: '1406008375',
                                  likes: { count: 2000 },
                                  comments: { count: 200 },
                                  link: 'http://photo2',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail2'
                                  } })
        [photo1, photo2]
      end

      before do
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', {}) { photos }
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', max_id: '7890') { [] }
      end

      it 'should log the issue and move on to the next photo' do
        expect(Rails.logger).to receive(:warn)
        importer.perform('1234')

        expect(InstagramPhoto.find('7890')).to be_present
      end
    end

    context 'when photo already exists in the index' do
      let(:photos) do
        photo1 = Hashie::Mash.new(id: 'already exists',
                                  user: { username: 'user1' },
                                  tags: %w[tag1 tag2],
                                  caption: { text: 'new caption' },
                                  created_time: '1404920005',
                                  likes: { count: 3000 },
                                  comments: { count: 300 },
                                  link: 'http://photo1',
                                  images: { thumbnail: {
                                    url: 'http://photo_thumbnail1'
                                  } })
        [photo1]
      end

      before do
        InstagramPhoto.create(id: 'already exists', username: 'user1', tags: %w[tag1 tag2], caption: 'initial caption', taken_at: Date.current, popularity: 101, url: 'http://instaphoto2', thumbnail_url: 'http://instaphoto_thumbnail2', album: 'album3')
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', {}) { photos }
        allow_any_instance_of(Instagram::Client).to receive(:user_recent_media).with('1234', max_id: 'already exists') { [] }
      end

      it 'should update the popularity field' do
        importer.perform('1234')

        already_exists = InstagramPhoto.find('already exists')
        expect(already_exists.album).to eq('album3')
        expect(already_exists.popularity).to eq(3300)
      end
    end

    context 'when Instagram API generates some error' do
      before do
        expect_any_instance_of(Instagram::Client).to receive(:user_recent_media).and_raise StandardError
      end

      it 'should log a warning and continue' do
        expect(Rails.logger).to receive(:warn)
        importer.perform('1234')
      end
    end
  end

  describe '.refresh' do
    before do
      allow(InstagramProfile).to receive(:find_each).and_yield(double(InstagramProfile, id: '123')).and_yield(double(InstagramProfile, id: '456'))
    end

    it 'should enqueue importing the last X days of photos' do
      InstagramPhotosImporter.refresh
      expect(InstagramPhotosImporter).to have_enqueued_sidekiq_job('123', InstagramPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
      expect(InstagramPhotosImporter).to have_enqueued_sidekiq_job('456', InstagramPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end
end
