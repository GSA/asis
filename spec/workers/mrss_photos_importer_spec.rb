# frozen_string_literal: true

require 'rails_helper'

describe MrssPhotosImporter do
  it { is_expected.to be_retryable true }
  it { is_expected.to be_unique }

  describe '#perform' do
    subject(:perform) do
      importer.perform(mrss_profile.name)
      MrssPhoto.refresh_index!
    end

    let(:mrss_profile) do
      MrssProfile.create({ id: mrss_url }, refresh: true)
    end
    let(:mrss_xml) { file_fixture('nasa.xml').read }
    let(:mrss_url) { 'http://some.mrss.url/importme.xml' }
    let(:importer) { described_class.new }

    before do
      stub_request(:get, mrss_url).to_return(body: mrss_xml)
      MrssPhoto.delete_all
      MrssPhoto.refresh_index!
    end

    it 'fetches the xml with the correct user agent' do
      perform
      expect(a_request(:get, mrss_url).with(headers: { user_agent: 'Oasis' })).
        to have_been_made
    end

    context 'when the URL has been redirected' do
      let(:new_url) { 'https://some.mrss.url/new.xml' }

      before do
        stub_request(:get, mrss_url).to_return(status: 301, headers: { location: new_url })
        stub_request(:get, new_url).to_return(body: mrss_xml)
      end

      it 'indexes the photos' do
        expect { perform }.to change{ MrssPhoto.count }.from(0).to(4)
      end
    end

    context 'when MRSS photo entries are returned' do
      it 'indexes the photos' do
        expect { perform }.to change{ MrssPhoto.count }.from(0).to(4)
      end

      it 'indexes the expected content' do
        perform
        photo = MrssPhoto.find(
          'http://www.nasa.gov/archive/archive/content/samantha-cristoforettis-birthday-celebration'
        )

        expect(photo.id).to eq(
          'http://www.nasa.gov/archive/archive/content/samantha-cristoforettis-birthday-celebration'
        )
        expect(photo.mrss_names.first).to eq(mrss_profile.name)
        expect(photo.title).to eq("Samantha Cristoforetti's Birthday Celebration")
        expect(photo.description).to match(/ISS043E142528/)
        expect(photo.taken_at).to eq(Date.parse('2015-05-04'))
        expect(photo.popularity).to eq(0)
        expect(photo.url).to eq(
          'http://www.nasa.gov/archive/archive/content/samantha-cristoforettis-birthday-celebration'
        )
        expect(photo.thumbnail_url).to eq(
          'http://www.nasa.gov/sites/default/files/styles/100x75/public/thumbnails/image/17147956078_0b4b9761d6_k.jpg?itok=BmnIF3ZZ'
        )
      end
    end

    context 'when photo cannot be created' do
      let(:photos) do
        photo1 = Hashie::Mash.new(entry_id: 'guid1',
                                  title: 'first photo',
                                  summary: 'summary for first photo',
                                  published: 'this will break it',
                                  thumbnail_url: 'http://photo_thumbnail1',
                                  url: 'http://photo1')
        photo2 = Hashie::Mash.new(entry_id: 'guid2',
                                  title: 'second photo',
                                  summary: 'summary for second photo',
                                  published: Time.parse('2014-10-22 14:24:00Z'),
                                  thumbnail_url: 'http://photo_thumbnail2',
                                  url: 'http://photo2')
        [photo1, photo2]
      end

      let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: photos) }

      before do
        allow(Feedjira::Feed).to receive(:parse).with(mrss_xml) { feed }
      end

      it 'logs the issue and moves on to the next photo' do
        expect(Rails.logger).to receive(:warn)
        importer.perform(mrss_profile.name)

        expect(MrssPhoto.find('guid2')).to be_present
      end
    end

    context 'when photo already exists in the index' do
      let(:photos) do
        photo1 = Hashie::Mash.new(entry_id: 'already exists',
                                  title: 'new title',
                                  summary: 'new summary',
                                  published: Time.parse('2014-10-22 14:24:00Z'),
                                  thumbnail_url: 'http://photo_thumbnail1',
                                  url: 'http://photo1')

        [photo1]
      end

      let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: photos) }

      before do
        allow(Feedjira::Feed).to receive(:parse).with(mrss_xml) { feed }

        MrssPhoto.create(id: 'already exists',
                         mrss_names: %w[existing_mrss_name],
                         tags: %w[tag1 tag2],
                         title: 'initial title',
                         description: 'initial description',
                         taken_at: Date.current,
                         popularity: 0,
                         url: 'http://mrssphoto2',
                         thumbnail_url: 'http://mrssphoto_thumbnail2',
                         album: 'album3')
      end

      it 'adds the mrss_name to the mrss_names array and leaves other meta data alone' do
        importer.perform(mrss_profile.name)

        already_exists = MrssPhoto.find('already exists')
        expect(already_exists.album).to eq('album3')
        expect(already_exists.popularity).to eq(0)
        expect(already_exists.title).to eq('initial title')
        expect(already_exists.description).to eq('initial description')
        expect(already_exists.tags).to match_array(%w[tag1 tag2])
        expect(already_exists.mrss_names).to match_array(
          ['existing_mrss_name', mrss_profile.name]
        )
      end
    end

    context 'when MRSS feed generates some error' do
      before do
        allow(Feedjira::Feed).to receive(:parse).and_raise StandardError
      end

      it 'logs a warning and continues' do
        expect(Rails.logger).to receive(:warn)
        importer.perform(mrss_profile.name)
      end
    end
  end

  describe '.refresh' do
    before do
      allow(MrssProfile).to receive(:find_each).
        and_yield(double(MrssProfile, name: '3', id: 'http://some/mrss.url/feed.xml1')).
        and_yield(double(MrssProfile, name: '4', id: 'http://some/mrss.url/feed.xml2'))
    end

    it 'enqueues importing the photos' do
      described_class.refresh
      expect(described_class).to have_enqueued_sidekiq_job('3')
      expect(described_class).to have_enqueued_sidekiq_job('4')
    end
  end
end
