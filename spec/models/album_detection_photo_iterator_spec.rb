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

  let(:iterator) { AlbumDetectionPhotoIterator.new(FlickrPhoto, PhotoFilter.new('owner', 'owner1').query_body) }

  it 'should run the album detector on each photo' do
    expect(AlbumDetector).to(receive(:detect_albums!).exactly(5).times { [] })
    iterator.run
  end

  describe 'assigning a default album' do
    context 'when there is a version conflict during the update' do
      let(:photo) { FlickrPhoto.create(id: 'photo1', owner: 'owner1', tags: [], title: 'title1 earth', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: []) }

      before do
        expect(photo).to receive(:update).and_raise Elasticsearch::Transport::Transport::Errors::Conflict
      end

      it 'should log a warning and continue' do
        expect(Rails.logger).to receive(:warn)
        AlbumDetector.detect_albums! photo
      end
    end
  end
end
