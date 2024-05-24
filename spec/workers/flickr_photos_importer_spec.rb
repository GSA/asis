# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

describe FlickrPhotosImporter do
  it { is_expected.to be_retryable true }
  it { is_expected.to be_unique }

  describe '#perform' do
    subject(:perform) do
      importer.perform(*args)
      FlickrPhoto.refresh_index!
    end
    let(:args) { %w[flickr_id user] }
    let(:importer) { described_class.new }

    before do
      FlickrPhoto.delete_all
      FlickrPhoto.refresh_index!
    end

    describe 'days_ago param' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: '', title: 'title1', description: 'desc 1', datetaken: Time.now.strftime('%Y-%m-%d %H:%M:%S'), views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: Time.now.to_i)
        photo2 = Hashie::Mash.new(id: 'photo2', owner: 'owner2', tags: '', title: 'title2', description: 'desc 2', datetaken: Time.now.strftime('%Y-%m-%d %H:%M:%S'), views: 200, url_o: 'http://photo2', url_q: 'http://photo_thumbnail2', dateupload: Time.now.to_i)
        photo3 = Hashie::Mash.new(id: 'photo3', owner: 'owner3', tags: '', title: 'title3', description: 'desc 3', datetaken: Time.now.strftime('%Y-%m-%d %H:%M:%S'), views: 300, url_o: 'http://photo3', url_q: 'http://photo_thumbnail3', dateupload: Time.now.to_i)
        photo4 = Hashie::Mash.new(id: 'photo4', owner: 'owner4', tags: '', title: 'title4', description: 'desc 4', datetaken: 8.days.ago.strftime('%Y-%m-%d %H:%M:%S'), views: 400, url_o: 'http://photo4', url_q: 'http://photo_thumbnail4', dateupload: 8.days.ago.to_i)
        photo5 = Hashie::Mash.new(id: 'photo5', owner: 'owner5', tags: '', title: 'title5', description: 'desc 5', datetaken: 9.days.ago.strftime('%Y-%m-%d %H:%M:%S'), views: 500, url_o: 'http://photo5', url_q: 'http://photo_thumbnail5', dateupload: 9.days.ago.to_i)

        batch1_photos = [photo1, photo2]
        batch2_photos = [photo3, photo4]
        batch3_photos = [photo5]

        allow(importer).to receive(:get_photos) do |id, profile_type, options|
          case options[:page]
          when 1 then OpenStruct.new(photos: batch1_photos, pages: 3)
          when 2 then OpenStruct.new(photos: batch2_photos, pages: 3)
          when 3 then OpenStruct.new(photos: batch3_photos, pages: 3)
          else OpenStruct.new(photos: [], pages: 3)
          end
        end
      end

      context 'when days_ago is specified' do
        let(:args) { ['flickr_id', 'user', 7] }

        it 'stops fetching more photos when the last photo of the current batch is before days_ago' do
          perform
          FlickrPhoto.refresh_index!
          expect(FlickrPhoto.count).to eq(4)
        end
      end

      context 'when days_ago is not specified' do
        let(:args) { %w[flickr_id user] }

        it 'fetches all the pages available' do
          perform
          expect(FlickrPhoto.count).to eq(5)
        end
      end
    end

    context 'when user photos are returned' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'tag1 tag2', title: 'title1', description: 'description1', datetaken: '2014-07-09 12:34:56', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'stores and indexes them' do
        perform
        first = FlickrPhoto.find('photo1')
        expect(first.id).to eq('photo1')
        expect(first.owner).to eq('owner1')
        expect(first.tags).to eq(%w[tag1 tag2])
        expect(first.title).to eq('title1')
        expect(first.description).to eq('description1')
        expect(first.taken_at).to eq(Date.parse('2014-07-09'))
        expect(first.popularity).to eq(100)
        expect(first.url).to eq('http://www.flickr.com/photos/owner1/photo1/')
        expect(first.thumbnail_url).to eq('http://photo_thumbnail1')
      end
    end

    context 'when group photos are returned' do
      let(:args) { %w[flickr_group_id group] }

      before do
        photo1 = Hashie::Mash.new(id: 'group_photo1', owner: 'owner1', tags: 'tag1 tag2', title: 'title1', description: 'description1', datetaken: '2014-07-09 12:34:56', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_group_id',
          'group',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'stores and indexes them with their group assigned' do
        perform
        first = FlickrPhoto.find('group_photo1')
        expect(first.id).to eq('group_photo1')
        expect(first.owner).to eq('owner1')
        expect(first.tags).to eq(%w[tag1 tag2])
        expect(first.groups).to eq(['flickr_group_id'])
        expect(first.title).to eq('title1')
        expect(first.description).to eq('description1')
        expect(first.taken_at).to eq(Date.parse('2014-07-09'))
        expect(first.popularity).to eq(100)
        expect(first.url).to eq('http://www.flickr.com/photos/owner1/group_photo1/')
        expect(first.thumbnail_url).to eq('http://photo_thumbnail1')
      end
    end

    context 'when photo contains vision:* tags and other machine tag stuff with a colon' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'tag1 vision:people=099 vision:groupshot=099 xmlns:dc=httppurlorgdcelements11 dc:identifier=httphdllocgovlocpnpggbain22915 tag2', title: 'title1', description: 'description1', datetaken: '2014-07-09 12:34:56', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'strips them' do
        perform
        first = FlickrPhoto.find('photo1')
        expect(first.tags).to eq(%w[tag1 tag2])
      end
    end

    context 'when photo contains datetaken with zero month or day' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'tag2', title: 'title1', description: 'description1', datetaken: '2014-00-00 00:00:00', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'assigns zero month as January and zero day as one' do
        perform
        first = FlickrPhoto.find('photo1')
        expect(first.taken_at).to eq(Date.parse('2014-01-01'))
      end
    end

    context 'when title/desc contain leading/trailing spaces' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'tag1 tag2', title: '     title1    ', description: '             ', datetaken: '2014-07-09 12:34:56', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'strips them' do
        perform
        first = FlickrPhoto.find('photo1')
        expect(first.title).to eq('title1')
        expect(first.description).to eq('')
      end
    end

    context 'when photo cannot be created' do
      before do
        photo1 = Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'hi', title: nil, description: 'tags are nil', datetaken: '2014-07-09 12:34:56', views: 100, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        photo2 = Hashie::Mash.new(id: 'photo2', owner: 'owner2', tags: 'tag2 tag3', title: 'title2', description: 'description2', datetaken: '2024-07-09 22:34:56', views: 200, url_o: 'http://photo2', url_q: 'http://photo_thumbnail2', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1, photo2]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
      end

      it 'logs the issue and moves on to the next photo' do
        expect(Rails.logger).to receive(:warn)
        perform
        expect(FlickrPhoto.find('photo2')).to be_present
      end
    end

    context 'when photo already exists in the index' do
      before do
        photo1 = Hashie::Mash.new(id: 'already exists', owner: 'owner1', tags: nil, title: 'new title', description: 'tags are nil', datetaken: '2014-07-09 12:34:56', views: 101, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_id',
          'user',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)

        FlickrPhoto.create(id: 'already exists', owner: 'owner1', tags: [], title: 'initial title', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      end

      it 'updates the popularity field' do
        perform
        already_exists = FlickrPhoto.find('already exists')
        expect(already_exists.popularity).to eq(101)
        expect(already_exists.album).to eq('album1')
      end
    end

    context 'when photo exists in the index and got fetched from a group pool' do
      let(:args) { %w[flickr_group_id group] }

      before do
        photo1 = Hashie::Mash.new(id: 'already exists with group', owner: 'owner1', tags: nil, title: 'new title', description: 'tags are nil', datetaken: '2014-07-09 12:34:56', views: 101, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_group_id',
          'group',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)

        FlickrPhoto.create(id: 'already exists with group', owner: 'owner1', tags: [], title: 'initial title', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      end

      it 'updates the popularity field' do
        perform
        already_exists = FlickrPhoto.find('already exists with group')
        expect(already_exists.popularity).to eq(101)
      end

      it 'adds the group_id to the unique set of groups' do
        perform
        already_exists = FlickrPhoto.find('already exists with group')
        expect(already_exists.groups).to include('flickr_group_id')
      end
    end

    context 'when photo exists in the index with a group and got fetched from the same group pool' do
      let(:args) { %w[flickr_group_id group] }

      before do
        photo1 = Hashie::Mash.new(id: 'already exists with group', owner: 'owner1', tags: nil, title: 'new title', description: 'tags are nil', datetaken: '2014-07-09 12:34:56', views: 101, url_o: 'http://photo1', url_q: 'http://photo_thumbnail1', dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with(
          'flickr_group_id',
          'group',
          {
            per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST,
            extras: FlickrPhotosImporter::EXTRA_FIELDS,
            page: 1
          }
        ).and_return(batch1_photos)
        FlickrPhoto.create(id: 'already exists with group', owner: 'owner1', tags: [], title: 'initial title', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: %w[group1 flickr_group_id])
      end

      it 'adds the group_id to the unique set of groups' do
        perform
        already_exists = FlickrPhoto.find('already exists with group')
        expect(already_exists.groups).to match_array(%w[group1 flickr_group_id])
      end
    end

    context 'when flickr owner is a user' do
      let(:flickr_user_client) { double('Flickr client for user call') }
      let(:no_results) { [] }
      before do
        allow(FlickRaw::Flickr).to receive(:new).and_return(flickr_user_client)
        allow(no_results).to receive(:pages).and_return 0
      end

      it 'calls the user section of the API' do
        expect(flickr_user_client).to receive_message_chain('people.getPublicPhotos').and_return(no_results)
        importer.perform('user1', 'user')
      end
    end

    context 'when flickr owner is a group' do
      let(:args) { %w[group1 group] }
      let(:flickr_group_client) { double('Flickr client for group call') }
      let(:no_results) { [] }

      before do
        allow(FlickRaw::Flickr).to receive(:new).and_return(flickr_group_client)
        allow(no_results).to receive(:pages).and_return 0
      end

      it 'calls the group section of the API' do
        expect(flickr_group_client).to receive_message_chain('groups.pools.getPhotos').and_return(no_results)
        perform
      end
    end

    context 'when Flickr API generates some error' do
      before do
        expect(FlickRaw::Flickr).to receive_message_chain('new.people.getPublicPhotos').and_raise StandardError
      end

      it 'logs a warning and continues' do
        expect(Rails.logger).to receive(:warn)
        importer.perform('user1', 'user')
      end
    end
  end

  describe '.refresh' do
    before do
      allow(FlickrProfile).to receive(:find_each).
        and_yield(double(FlickrProfile, id: 'abc', profile_type: 'user')).
        and_yield(double(FlickrProfile, id: 'def', profile_type: 'group'))
    end

    it 'enqueues importing the last X days of photos' do
      described_class.refresh
      expect(described_class).to have_enqueued_sidekiq_job('abc', 'user', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
      expect(described_class).to have_enqueued_sidekiq_job('def', 'group', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end
end
