require 'rails_helper'

describe MrssPhotosImporter do
  it { should be_retryable true }
  it { should be_unique }

  describe "#perform" do
    before do
      MrssPhoto.delete_all
      sleep 1
      MrssPhoto.refresh_index!
      @mrss_profile = MrssProfile.create(id: 'http://some.mrss.url/importme.xml')
      MrssProfile.refresh_index!
    end

    let(:importer) { MrssPhotosImporter.new }
    let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: []) }

    it "should fetch the photos from the MRSS feed" do
      expect(Feedjira::Feed).to receive(:fetch_and_parse).with('http://some.mrss.url/importme.xml', MrssPhotosImporter::FEEDJIRA_OPTIONS) { feed }
      importer.perform(@mrss_profile.name)
    end

    context 'when MRSS photo entries are returned' do
      let(:photos) do
        photo1 = Hashie::Mash.new(entry_id: "guid1",
                                  title: 'first photo',
                                  summary: 'summary for first photo',
                                  published: Time.parse("2014-10-22 14:24:00Z"),
                                  thumbnail_url: "http://photo_thumbnail1",
                                  url: 'http://photo1')
        photo2 = Hashie::Mash.new(entry_id: "guid2",
                                  title: 'second photo',
                                  summary: 'summary for second photo',
                                  published: Time.parse("2014-10-22 14:24:00Z"),
                                  thumbnail_url: "http://photo_thumbnail2",
                                  url: 'http://photo2')
        [photo1, photo2]
      end

      let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: photos) }

      before do
        expect(Feedjira::Feed).to receive(:fetch_and_parse).with(@mrss_profile.id, MrssPhotosImporter::FEEDJIRA_OPTIONS) { feed }
      end

      it "should store and index them" do
        importer.perform(@mrss_profile.name)
        first = MrssPhoto.find("guid1")
        expect(first.id).to eq('guid1')
        expect(first.mrss_names.first).to eq(@mrss_profile.name)
        expect(first.title).to eq('first photo')
        expect(first.description).to eq('summary for first photo')
        expect(first.taken_at).to eq(Date.parse("2014-10-22"))
        expect(first.popularity).to eq(0)
        expect(first.url).to eq('http://photo1')
        expect(first.thumbnail_url).to eq('http://photo_thumbnail1')
        second = MrssPhoto.find("guid2")
        expect(second.id).to eq('guid2')
        expect(second.mrss_names.first).to eq(@mrss_profile.name)
        expect(second.title).to eq('second photo')
        expect(second.description).to eq('summary for second photo')
        expect(second.taken_at).to eq(Date.parse("2014-10-22"))
        expect(second.popularity).to eq(0)
        expect(second.url).to eq('http://photo2')
        expect(second.thumbnail_url).to eq('http://photo_thumbnail2')
      end
    end

    context 'when photo cannot be created' do
      let(:photos) do
        photo1 = Hashie::Mash.new(entry_id: "guid1",
                                  title: 'first photo',
                                  summary: 'summary for first photo',
                                  published: "this will break it",
                                  thumbnail_url: "http://photo_thumbnail1",
                                  url: 'http://photo1')
        photo2 = Hashie::Mash.new(entry_id: "guid2",
                                  title: 'second photo',
                                  summary: 'summary for second photo',
                                  published: Time.parse("2014-10-22 14:24:00Z"),
                                  thumbnail_url: "http://photo_thumbnail2",
                                  url: 'http://photo2')
        [photo1, photo2]
      end

      let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: photos) }

      before do
        expect(Feedjira::Feed).to receive(:fetch_and_parse).with(@mrss_profile.id, MrssPhotosImporter::FEEDJIRA_OPTIONS) { feed }
      end

      it "should log the issue and move on to the next photo" do
        expect(Rails.logger).to receive(:warn)
        importer.perform(@mrss_profile.name)

        expect(MrssPhoto.find("guid2")).to be_present
      end
    end

    context 'when photo already exists in the index' do
      let(:photos) do
        photo1 = Hashie::Mash.new(entry_id: "already exists",
                                  title: 'new title',
                                  summary: 'new summary',
                                  published: Time.parse("2014-10-22 14:24:00Z"),
                                  thumbnail_url: "http://photo_thumbnail1",
                                  url: 'http://photo1')

        [photo1]
      end

      let(:feed) { double(Feedjira::Parser::Oasis::Mrss, entries: photos) }

      before do
        expect(Feedjira::Feed).to receive(:fetch_and_parse).with(@mrss_profile.id, MrssPhotosImporter::FEEDJIRA_OPTIONS) { feed }
        MrssPhoto.create(id: "already exists", mrss_names: %w(existing_mrss_name), tags: %w(tag1 tag2), title: 'initial title', description: 'initial description', taken_at: Date.current, popularity: 0, url: "http://mrssphoto2", thumbnail_url: "http://mrssphoto_thumbnail2", album: 'album3')
      end

      it "should add the mrss_name to the mrss_names array and leave other meta data alone" do
        importer.perform(@mrss_profile.name)

        already_exists = MrssPhoto.find("already exists")
        expect(already_exists.album).to eq("album3")
        expect(already_exists.popularity).to eq(0)
        expect(already_exists.title).to eq('initial title')
        expect(already_exists.description).to eq('initial description')
        expect(already_exists.tags).to match_array(%w(tag1 tag2))
        expect(already_exists.mrss_names).to match_array(['existing_mrss_name', @mrss_profile.name])
      end
    end

    context 'when MRSS feed generates some error' do
      before do
        expect(Feedjira::Feed).to receive(:fetch_and_parse).and_raise Exception
      end

      it 'should log a warning and continue' do
        expect(Rails.logger).to receive(:warn)
        importer.perform(@mrss_profile.name)
      end
    end

  end

  describe ".refresh" do
    before do
      allow(MrssProfile).to receive(:find_each).and_yield(double(MrssProfile, name: "3", id: 'http://some/mrss.url/feed.xml1')).and_yield(double(MrssProfile, name: "4", id: 'http://some/mrss.url/feed.xml2'))
    end

    it 'should enqueue importing the photos' do
      MrssPhotosImporter.refresh
      expect(MrssPhotosImporter).to have_enqueued_sidekiq_job("3")
      expect(MrssPhotosImporter).to have_enqueued_sidekiq_job("4")
    end
  end
end
