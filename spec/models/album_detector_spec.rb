# frozen_string_literal: true

require 'rails_helper'

describe AlbumDetector do
  describe 'assigning a default album' do
    subject(:detect_albums) { described_class.detect_albums!(photo) }

    let(:photo) do
      FlickrPhoto.create(
        id: 'flickr photo',
        owner: 'owner1',
        tags: [],
        title: 'title1 earth',
        description: 'desc 1',
        taken_at: Date.current,
        popularity: 100,
        url: 'http://photo1',
        thumbnail_url: 'http://photo_thumbnail1',
        album: nil,
        groups: []
      )
    end

    it 'assigns the album name' do
      allow(photo).to receive(:update)
      detect_albums
      expect(photo).to have_received(:update).with(album: photo.generate_album_name)
    end

    context 'when something goes wrong' do
      before do
        allow(photo).to receive(:update).and_raise StandardError.new('failure')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        detect_albums
        expect(Rails.logger).to have_received(:error).
          with("Unable to assign album to photo 'flickr photo': failure")
      end

      it 'does not raise an error' do
        expect { detect_albums }.not_to raise_error
      end
    end
  end
end
