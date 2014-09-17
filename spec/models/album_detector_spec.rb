require 'rails_helper'

describe AlbumDetector do
  describe "assigning a default album" do
    context 'when there is a version conflict during the update' do
      let(:photo) { FlickrPhoto.create(id: "photo1", owner: "owner1", profile_type: 'user', tags: [], title: "title1 earth", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1", album: 'album1') }

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