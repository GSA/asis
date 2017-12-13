require 'rails_helper'

describe MrssAlbumDetector do
  context 'when 4 or more other MRSS photos are sufficiently similar in their tags, title, and description fields' do
    before do
      5.times do |x|
        i = x + 1
        MrssPhoto.create(id: "photo #{i}", mrss_names: %w(95 96), tags: ['alpha', 'bravo', 'charlie', i.ordinalize],
                           title: "#{i.ordinalize} Aircrew members traverse SERE combat survival training challenges",
                           description: "#{i.ordinalize} Aircrew members simulate being captured by a mock adversary during a combat survival refresher course",
                           taken_at: Date.parse("2014-10-24"), popularity: 0, url: "http://photo#{i}", thumbnail_url: "http://photo_thumbnail#{i}",
                           album: "photo #{i}")
      end
      MrssPhoto.refresh_index!
    end

    let(:photo) { MrssPhoto.find "photo 1" }

    it 'should assign them all to the same album' do
      AlbumDetector.detect_albums! photo
      5.times do |x|
        i = x + 1
        expect(MrssPhoto.find("photo #{i}").album).to eq("95:96:2014-10-24:photo 1")
      end
    end
  end
end
