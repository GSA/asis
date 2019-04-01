# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
require 'rails_helper'

describe InstagramAlbumDetector do
  context 'when 4 or more other Instagram photos are sufficiently similar in their tags and caption fields' do
    before do
      5.times do |x|
        i = x + 1
        InstagramPhoto.create(id: "photo #{i}", username: 'username1',
                              tags: ['alpha', 'bravo', 'charlie', i.ordinalize],
                              caption: "#{i.ordinalize} title from unverified data provided by the Bain News Service on the negatives or caption cards",
                              taken_at: Date.parse('2014-09-16'), popularity: 100 + i, url: "http://photo#{i}", thumbnail_url: "http://photo_thumbnail#{i}",
                              album: "photo #{i}")
      end
      InstagramPhoto.refresh_index!
    end

    let(:photo) { InstagramPhoto.find 'photo 1' }

    it 'should assign them all to the same album' do
      AlbumDetector.detect_albums! photo
      5.times do |x|
        i = x + 1
        expect(InstagramPhoto.find("photo #{i}").album).to eq('username1:2014-09-16:photo 1')
      end
    end
  end
end
