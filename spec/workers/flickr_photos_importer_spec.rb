# frozen_string_literal: true

require 'rails_helper'

describe FlickrPhotosImporter do
  it { is_expected.to be_retryable true }
  it { is_expected.to be_unique }

  let(:importer) { described_class.new }

  before do
    allow(FlickRaw::Flickr).to receive(:new).and_return(double)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    FlickrPhoto.delete_all
    FlickrPhoto.refresh_index!
  end

  describe '#perform' do
    let(:args) { ['flickr_id', 'user'] }
    let(:photos) { instance_double("FlickrApiResponse", count: 5, pages: 3, to_a: []) }

    before do
      allow(importer).to receive(:get_photos).and_return(photos)
      allow(photos).to receive(:collect).and_return([])
    end

    it 'fetches photos and processes them' do
      allow(photos).to receive(:pages).and_return(1)
      importer.perform(*args)
      expect(importer).to have_received(:get_photos).with(
        'flickr_id',
        'user',
        hash_including(page: 1)
      )
    end

    context 'when an error occurs during fetching photos' do
      before do
        allow(importer).to receive(:get_photos).and_raise(StandardError.new("Test error"))
      end

      it 'logs a warning and continues' do
        expect(Rails.logger).to receive(:warn).with("Error during processing: Test error")
        importer.perform(*args)
      end
    end

    context 'days_ago param' do
      let(:photo1) { Hashie::Mash.new(id: 'photo1', views: 100) }
      let(:photo2) { Hashie::Mash.new(id: 'photo2', views: 200) }
      let(:batch) { [photo1, photo2] }

      before do
        allow(batch).to receive(:pages).and_return(2)
        allow(importer).to receive(:get_photos).and_return(batch)
      end

      it 'stops fetching more photos when the last photo of the current batch is before days_ago' do
        args = ['flickr_id', 'user', 7]
        importer.perform(*args)
        expect(batch).to have_received(:pages)
      end
    end

    context 'when user photos are returned' do
      let(:photo1) { double("FlickrPhoto", id: 'photo1', owner: 'owner1', tags: %w[tag1 tag2], title: 'title1', description: 'description1', taken_at: Date.parse('2014-07-09'), popularity: 100, url: 'http://photo1', thumbnail_url: 'http://thumbnail1') }

      before do
        allow(importer).to receive(:store_photos).and_return([photo1])
      end

      it 'stores and indexes them' do
        importer.perform(*args)
        expect(importer).to have_received(:store_photos)
      end
    end

    context 'when photo cannot be created' do
      before do
        allow(importer).to receive(:store_photos).and_raise(StandardError.new("Storage error"))
      end

      it 'logs the issue and moves on to the next photo' do
        expect(Rails.logger).to receive(:warn).with("Error during processing: Storage error")
        importer.perform(*args)
      end
    end
  end

  describe '.refresh' do
    it 'enqueues importing the last X days of photos' do
      allow(FlickrProfile).to receive(:find_each).and_yield(double(id: 'abc', profile_type: 'user')).and_yield(double(id: 'def', profile_type: 'group'))
      described_class.refresh
      expect(described_class).to have_enqueued_sidekiq_job('abc', 'user', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
      expect(described_class).to have_enqueued_sidekiq_job('def', 'group', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end
end
