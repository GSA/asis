require 'rails_helper'

describe FlickrAlbumDetector do
  context 'when 4 or more other Flickr photos are sufficiently similar in their tags, title, and description fields' do
    before do
      5.times do |x|
        i = x + 1
        FlickrPhoto.create(id: "photo #{i}", owner: "owner1", tags: ['alpha', 'bravo', 'charlie', i.ordinalize],
                           title: "#{i.ordinalize} presidential visit to Mars",
                           description: "#{i.ordinalize} title from unverified data provided by the Bain News Service on the negatives or caption cards",
                           taken_at: Date.parse("2014-09-16"), popularity: 100+i, url: "http://photo#{i}", thumbnail_url: "http://photo_thumbnail#{i}",
                           album: "photo #{i}", groups: [])
      end
      FlickrPhoto.refresh_index!
    end

    let(:photo) { FlickrPhoto.find "photo 1" }

    it 'should assign them all to the same album' do
      AlbumDetector.detect_albums! photo
      5.times do |x|
        i = x + 1
        expect(FlickrPhoto.find("photo #{i}").album).to eq("owner1:2014-09-16:photo 1")
      end
    end
  end
end
