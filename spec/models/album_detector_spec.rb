# frozen_string_literal: true

require 'rails_helper'

describe AlbumDetector do
  describe 'assigning a default album' do
    context 'when the photo is version 1 (newly created)' do
      let(:photo) do
        FlickrPhoto.create(id: 'newly created flickr photo', owner: 'owner1', tags: [],
                           title: 'title1 earth', description: 'desc 1', taken_at: Date.current,
                           popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1',
                           album: nil, groups: [])
      end

      before do
        expect(photo._version).to eq(1)
      end

      it 'does not care about versioning the update' do
        expect(photo).to receive(:update).with({ album: photo.generate_album_name }, {})
        described_class.detect_albums! photo
      end
    end

    context 'when there is a version conflict during the update' do
      let(:photo) do
        FlickrPhoto.create(id: 'photo version conflict', owner: 'owner1', tags: [],
                           title: 'title1 earth', description: 'desc 1', taken_at: Date.current,
                           popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1',
                           album: 'album1', groups: [])
      end

      before do
        expect(photo).to receive(:update).and_raise Elasticsearch::Transport::Transport::Errors::Conflict
      end

      it 'logs a warning and continue' do
        expect(Rails.logger).to receive(:warn)
        described_class.detect_albums! photo
      end
    end
  end
end
