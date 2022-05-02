# frozen_string_literal: true

require 'rails_helper'

describe AlbumDetectionPhotoIterator, 'run' do
  before do
    FlickrPhoto.delete_all
    5.times do |x|
      i = x + 1
      FlickrPhoto.create(id: "photo #{i}", owner: 'owner1', tags: ['alpha', 'bravo', 'charlie', i.ordinalize],
                         title: "#{i.ordinalize} presidential visit to Mars",
                         description: "#{i.ordinalize} title from unverified data provided by the Bain News Service on the negatives or caption cards",
                         taken_at: Date.parse('2014-09-16'), popularity: 100 + i, url: "http://photo#{i}", thumbnail_url: "http://photo_thumbnail#{i}",
                         album: "photo #{i}", groups: [])
    end
    FlickrPhoto.refresh_index!
  end

  let(:iterator) { described_class.new(FlickrPhoto, PhotoFilter.new('owner', 'owner1').query_body) }

  it 'runs the album detector on each photo' do
    expect(AlbumDetector).to(receive(:detect_albums!).exactly(5).times { [] })
    iterator.run
  end
end
