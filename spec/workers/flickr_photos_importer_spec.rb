require 'rails_helper'

describe FlickrPhotosImporter do
  it { should be_retryable true }
  it { should be_unique }

  describe "#perform" do
    before do
      FlickrPhoto.gateway.delete_index!
      FlickrPhoto.create_index!
    end

    let(:importer) { FlickrPhotosImporter.new }

    describe "days_ago param" do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "", title: "title1", description: "desc 1", datetaken: Time.now.strftime("%Y-%m-%d %H:%M:%S"), views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: Time.now.to_i)
        photo2 = Hashie::Mash.new(id: "photo2", owner: "owner2", profile_type: 'user', tags: "", title: "title2", description: "desc 2", datetaken: Time.now.strftime("%Y-%m-%d %H:%M:%S"), views: 200, url_o: "http://photo2", url_q: "http://photo_thumbnail2", dateupload: Time.now.to_i)
        photo3 = Hashie::Mash.new(id: "photo3", owner: "owner3", profile_type: 'user', tags: "", title: "title3", description: "desc 3", datetaken: Time.now.strftime("%Y-%m-%d %H:%M:%S"), views: 300, url_o: "http://photo3", url_q: "http://photo_thumbnail3", dateupload: Time.now.to_i)
        photo4 = Hashie::Mash.new(id: "photo4", owner: "owner4", profile_type: 'user', tags: "", title: "title4", description: "desc 4", datetaken: 8.days.ago.strftime("%Y-%m-%d %H:%M:%S"), views: 400, url_o: "http://photo4", url_q: "http://photo_thumbnail4", dateupload: 8.days.ago.to_i)
        photo5 = Hashie::Mash.new(id: "photo5", owner: "owner5", profile_type: 'user', tags: "", title: "title5", description: "desc 5", datetaken: 9.days.ago.strftime("%Y-%m-%d %H:%M:%S"), views: 500, url_o: "http://photo5", url_q: "http://photo_thumbnail5", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1, photo2]
        batch2_photos = [photo3, photo4]
        batch3_photos = [photo5]
        allow(batch1_photos).to receive(:pages).and_return(3)
        allow(batch2_photos).to receive(:pages).and_return(3)
        allow(batch3_photos).to receive(:pages).and_return(3)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 2 }).and_return(batch2_photos)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 3 }).and_return(batch3_photos)
      end

      context 'when days_ago is specified' do
        it "should stop fetching more photos when the last photo of the current batch is before days_ago" do
          importer.perform('flickr id', 'user', 7)
          FlickrPhoto.refresh_index!
          expect(FlickrPhoto.count).to eq(4)
        end
      end

      context 'when days_ago is not specified' do
        it "should fetch all the pages available" do
          importer.perform('flickr id', 'user')
          FlickrPhoto.refresh_index!
          expect(FlickrPhoto.count).to eq(5)
        end
      end
    end

    context 'when photos are returned' do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "tag1 tag2", title: "title1", description: "description1", datetaken: "2014-07-09 12:34:56", views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
      end

      it "should store and index them" do
        importer.perform('flickr id', 'user')
        first = FlickrPhoto.find("photo1")
        expect(first.id).to eq('photo1')
        expect(first.owner).to eq('owner1')
        expect(first.tags).to eq(%w(tag1 tag2))
        expect(first.title).to eq('title1')
        expect(first.description).to eq('description1')
        expect(first.taken_at).to eq(Date.parse("2014-07-09"))
        expect(first.popularity).to eq(100)
        expect(first.url).to eq('http://www.flickr.com/photos/owner1/photo1/')
        expect(first.thumbnail_url).to eq('http://photo_thumbnail1')
      end
    end

    context 'when photo contains vision:* tags and other machine tag stuff with a colon' do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "tag1 vision:people=099 vision:groupshot=099 xmlns:dc=httppurlorgdcelements11 dc:identifier=httphdllocgovlocpnpggbain22915 tag2", title: "title1", description: "description1", datetaken: "2014-07-09 12:34:56", views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
      end

      it "should strip them" do
        importer.perform('flickr id', 'user')
        first = FlickrPhoto.find("photo1")
        expect(first.tags).to eq(%w(tag1 tag2))
      end
    end

    context 'when photo contains datetaken with zero month or day' do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "tag2", title: "title1", description: "description1", datetaken: "2014-00-00 00:00:00", views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
      end

      it "should assign zero month as January and zero day as one" do
        importer.perform('flickr id', 'user')
        first = FlickrPhoto.find("photo1")
        expect(first.taken_at).to eq(Date.parse("2014-01-01"))
      end
    end

    context 'when title/desc contain leading/trailing spaces' do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "tag1 tag2", title: "     title1    ", description: "             ", datetaken: "2014-07-09 12:34:56", views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
      end

      it "should strip them" do
        importer.perform('flickr id', 'user')
        first = FlickrPhoto.find("photo1")
        expect(first.title).to eq('title1')
        expect(first.description).to eq('')
      end
    end

    context 'when photo cannot be created' do
      before do
        photo1 = Hashie::Mash.new(id: "photo1", owner: "owner1", profile_type: 'user', tags: "hi", title: nil, description: "tags are nil", datetaken: "2014-07-09 12:34:56", views: 100, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        photo2 = Hashie::Mash.new(id: "photo2", owner: "owner2", profile_type: 'user', tags: "tag2 tag3", title: "title2", description: "description2", datetaken: "2024-07-09 22:34:56", views: 200, url_o: "http://photo2", url_q: "http://photo_thumbnail2", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1, photo2]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
      end

      it "should log the issue and move on to the next photo" do
        expect(Rails.logger).to receive(:warn)
        importer.perform('flickr id', 'user')
        expect(FlickrPhoto.find("photo2")).to be_present
      end
    end

    context 'when photo already exists in the index' do
      before do
        photo1 = Hashie::Mash.new(id: "already exists", owner: "owner1", profile_type: 'user', tags: nil, title: "new title", description: "tags are nil", datetaken: "2014-07-09 12:34:56", views: 101, url_o: "http://photo1", url_q: "http://photo_thumbnail1", dateupload: 9.days.ago.to_i)
        batch1_photos = [photo1]
        allow(batch1_photos).to receive(:pages).and_return(1)
        allow(importer).to receive(:get_photos).with("flickr id", "user", { per_page: FlickrPhotosImporter::MAX_PHOTOS_PER_REQUEST, extras: FlickrPhotosImporter::EXTRA_FIELDS, page: 1 }).and_return(batch1_photos)
        FlickrPhoto.create(id: "already exists", owner: "owner1", profile_type: 'user', tags: [], title: "initial title", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1", album: 'album1')
      end

      it "should update the popularity field" do
        importer.perform('flickr id', 'user')
        already_exists = FlickrPhoto.find("already exists")
        expect(already_exists.popularity).to eq(101)
        expect(already_exists.album).to eq("album1")
      end
    end

    context 'when flickr owner is a user' do
      let(:flickr_user_client) { double('Flickr client for user call') }
      let(:no_results) { [] }
      before do
        allow(FlickRaw::Flickr).to receive(:new).and_return(flickr_user_client)
        allow(no_results).to receive(:pages).and_return 0
      end

      it 'should call the user section of the API' do
        expect(flickr_user_client).to receive_message_chain("people.getPublicPhotos").and_return(no_results)
        importer.perform('user1', 'user')
      end
    end

    context 'when flickr owner is a group' do
      let(:flickr_group_client) { double('Flickr client for group call') }
      let(:no_results) { [] }
      before do
        allow(FlickRaw::Flickr).to receive(:new).and_return(flickr_group_client)
        allow(no_results).to receive(:pages).and_return 0
      end

      it 'should call the group section of the API' do
        expect(flickr_group_client).to receive_message_chain("groups.pools.getPhotos").and_return(no_results)
        importer.perform('group1', 'group')
      end
    end

    context 'when Flickr API generates some error' do
      before do
        expect(FlickRaw::Flickr).to receive_message_chain("new.people.getPublicPhotos").and_raise Exception
      end

      it 'should log a warning and continue' do
        expect(Rails.logger).to receive(:warn)
        importer.perform('user1', 'user')
      end
    end
  end

  describe ".refresh" do
    before do
      allow(FlickrProfile).to receive(:find_each)
                              .and_yield(double(FlickrProfile, id: 'abc', profile_type: 'user'))
                              .and_yield(double(FlickrProfile, id: 'def', profile_type: 'group'))
    end

    it 'should enqueue importing the last X days of photos' do
      FlickrPhotosImporter.refresh
      expect(FlickrPhotosImporter).to have_enqueued_job('abc', 'user', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
      expect(FlickrPhotosImporter).to have_enqueued_job('def', 'group', FlickrPhotosImporter::DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end

end