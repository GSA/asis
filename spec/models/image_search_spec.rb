# frozen_string_literal: true

require 'rails_helper'

describe ImageSearch do
  before do
    FlickrPhoto.delete_all
    MrssPhoto.delete_all
  end

  describe 'filtering on flickr/mrss profiles' do
    before do
      FlickrPhoto.create(id: 'photo1', owner: 'owner1', tags: [], title: 'title1 earth', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1')
      FlickrPhoto.create(id: 'photo2', owner: 'owner2', tags: [], title: 'title2 earth', description: 'desc 2', taken_at: Date.current, popularity: 100, url: 'http://photo2', thumbnail_url: 'http://photo_thumbnail2', album: 'album2', groups: %w[group1])
      mrss_profile = MrssProfile.create(id: 'http://some/mrss.url/feed.xml3')
      MrssProfile.refresh_index!
      MrssPhoto.create(id: 'guid1', mrss_names: [mrss_profile.name], tags: %w[tag1 tag2], title: 'mrss earth title', description: 'initial description', taken_at: Date.current, popularity: 0, url: 'http://mrssphoto2', thumbnail_url: 'http://mrssphoto_thumbnail2', album: 'album3')
      MrssPhoto.refresh_index!
      FlickrPhoto.refresh_index!
    end

    it 'filters on flickr users' do
      image_search = described_class.new('earth', flickr_users: ['owner1'])
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('title1 earth')
    end

    it 'filters on flickr groups' do
      image_search = described_class.new('earth', flickr_groups: ['group1'])
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('title2 earth')
    end

    it 'filters on the union of flickr groups and users' do
      image_search = described_class.new('earth', flickr_groups: ['group1'], flickr_users: ['owner1'])
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(2)
    end

    it 'filters on MRSS feeds' do
      image_search = described_class.new('earth', mrss_names: [MrssProfile.all.last.name])
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('mrss earth title')
    end
  end
end
