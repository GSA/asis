# frozen_string_literal: true

require 'rails_helper'

describe FlickrPhotosImporter do
  it { is_expected.to be_retryable true }
  it { is_expected.to be_unique }

  let(:importer) { described_class.new }

  before do
    FlickrPhoto.delete_all
    FlickrPhoto.refresh_index!
    allow(FlickRaw::Flickr).to receive(:new).and_return(double)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
  end

  describe '#perform' do
    let(:args) { ['flickr_id', 'user'] }
    let(:photo_batch) { instance_double("FlickrApiResponse", count: 5, pages: 3, to_a: []) }

    context 'general operations' do
      before do
        allow(importer).to receive(:get_photos).and_return(photo_batch)
        allow(photo_batch).to receive(:collect).and_return([])
      end

      it 'fetches photos and processes them without error' do
        allow(photo_batch).to receive(:pages).and_return(1)
        expect { importer.perform(*args) }.not_to raise_error
      end
    end

    context 'error handling' do
      it 'logs a warning and continues when an error occurs during fetching' do
        allow(importer).to receive(:get_photos).and_raise(StandardError, "Test error")
        expect(Rails.logger).to receive(:warn).with("Error during processing: Test error")
        expect { importer.perform(*args) }.not_to raise_error
      end
    end

    describe 'photo processing in batches' do
      let(:photo1) { Hashie::Mash.new(id: 'photo1', owner: 'owner1', tags: 'tag1 tag2', title: 'title1', description: 'description1', datetaken: '2014-07-09', views: 100, url_o: 'http://photo1', url_q: 'http://thumbnail1', dateupload: Time.now.to_i) }
      let(:photo2) { Hashie::Mash.new(id: 'photo2', owner: 'owner2', tags: 'tag3 tag4', title: 'title2', description: 'description2', datetaken: '2014-07-10', views: 200, url_o: 'http://photo2', url_q: 'http://thumbnail2', dateupload: Time.now.to_i) }
      let(:batch) { [photo1, photo2] }

      before do
        allow(batch).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with('flickr_id', 'user', hash_including(page: 1)).and_return(batch)
        allow(importer).to receive(:store_photos).and_return(batch)
      end

      it 'processes all photos received' do
        importer.perform(*args)
        expect(importer).to have_received(:store_photos)
      end

      it 'handles days_ago parameter correctly' do
        args.append(7)  # Adding a 'days_ago' parameter
        importer.perform(*args)
        expect(importer).to have_received(:get_photos).with('flickr_id', 'user', hash_including(days_ago: 7))
      end
    end

    context 'photo storage and indexing' do
      before do
        allow(importer).to receive(:store_photos) { |photos| photos }
      end

      it 'indexes photos correctly and updates database' do
        photos = [Hashie::Mash.new(id: 'photo1', views: 100)]
        allow(importer).to receive(:get_photos).and_return(photos)
        importer.perform(*args)
        expect(FlickrPhoto.exists?(id: 'photo1')).to be true
      end

      it 'handles indexing errors gracefully' do
        photos = [Hashie::Mash.new(id: 'photo1', views: 100)]
        allow(importer).to receive(:get_photos).and_return(photos)
        allow(FlickrPhoto).to receive(:create).and_raise(StandardError, "Indexing failed")
        expect { importer.perform(*args) }.not_to raise_error
        expect(Rails.logger).to receive(:warn).with(/Indexing failed/)
      end
    end
  end

  describe '.refresh' do
    it 'enqueues importing the last X days of photos for all profiles' do
      allow(FlickrProfile).to receive(:find_each).and_yield(double(id: 'abc', profile_type: 'user')).and_yield(double(id: 'def', profile_type: 'group'))
      described_class.refresh
      expect(described_class).to have_enqueued_sidekiq_job('abc', 'user', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
      expect(described_class).to have_enqueued_sidekiq_job('def', 'group', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end
end
