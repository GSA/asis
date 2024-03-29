# frozen_string_literal: true

require 'rails_helper'

describe ImageSearch do
  before do
    FlickrPhoto.delete_all
    MrssPhoto.delete_all
  end

  context 'when relevant results exist in Flickr and MRSS indexes' do
    before do
      FlickrPhoto.create(id: 'photo1', owner: 'owner1', tags: [], title: 'title1 petrol', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      FlickrPhoto.refresh_index!
      MrssPhoto.create(id: 'guid', mrss_names: ['some url'], tags: %w[tag1 tag2], title: 'petrol title', description: 'initial description', taken_at: Date.current, popularity: 0, url: 'http://mrssphoto2', thumbnail_url: 'http://mrssphoto_thumbnail2', album: 'album3')
      MrssPhoto.refresh_index!
    end

    it 'returns results from all indexes' do
      image_search = described_class.new('gas', {})
      image_search_results = image_search.search
      expect(image_search_results.results.collect(&:type).uniq).to match_array(%w[FlickrPhoto MrssPhoto])
    end
  end

  context 'when smooshed user query matches tag in either Mrss or Flickr indexes' do
    before do
      FlickrPhoto.create(id: 'photo1', owner: 'owner1', tags: %w[apollo11 space], title: 'title1 earth', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      FlickrPhoto.refresh_index!
      MrssPhoto.create(id: '123456', username: 'user1', tags: %w[earth apollo11], caption: 'first photo of earth', taken_at: Date.current, popularity: 101, url: 'http://photo2', thumbnail_url: 'http://photo_thumbnail2', album: 'album2')
      MrssPhoto.refresh_index!
    end

    it 'returns results from both indexes' do
      image_search = described_class.new('apollo 11', {})
      image_search_results = image_search.search
      expect(image_search_results.results.collect(&:type).uniq).to match_array(%w[MrssPhoto FlickrPhoto])
    end
  end

  context 'when exact phrase matches' do
    before do
      FlickrPhoto.create(id: 'phrase match 1', owner: 'owner1', tags: %w[jeffersonmemorial], title: 'jefferson township Petitions and Memorials', description: 'stuff about jefferson memorial', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      FlickrPhoto.create(id: 'phrase match 2', owner: 'owner1', tags: %w[jeffersonmemorial], title: 'jefferson Memorial and township Petitions', description: 'stuff about jefferson memorial', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      FlickrPhoto.refresh_index!
    end

    it 'positively influences the relevancy score' do
      image_search = described_class.new('jefferson memorial', {})
      image_search_results = image_search.search
      expect(image_search_results.results.first.title).to eq('jefferson Memorial and township Petitions')
    end
  end

  context 'when search term yields no results but a similar spelling does have results' do
    before do
      # This spec can fail intermittently due to cruft from deleted documents.
      # To avoid this, we completely recreate the indices (see note in spec/rails_helper.rb):
      TestServices.delete_es_indexes
      TestServices.create_es_indexes

      FlickrPhoto.create(id: 'photo1', owner: 'owner1', tags: [], title: 'title1 earth', description: 'desc 1', taken_at: Date.current, popularity: 100, url: 'http://photo1', thumbnail_url: 'http://photo_thumbnail1', album: 'album1', groups: [])
      MrssPhoto.create(id: '123456', username: 'user1', tags: %w[tag1 tag2], title: 'photo of the cassini probe', taken_at: Date.current, popularity: 101, url: 'http://photo2', thumbnail_url: 'http://photo_thumbnail2', album: 'album2')
      MrssPhoto.refresh_index!
      FlickrPhoto.refresh_index!
    end

    it 'returns results for the close spelling' do
      image_search = described_class.new('casini', {})
      image_search_results = image_search.search
      expect(image_search_results.results.first.title).to eq('photo of the cassini probe')
      expect(image_search_results.suggestion['text']).to eq('cassini')
      expect(image_search_results.suggestion['highlighted']).to eq('<strong>cassini</strong>')
    end
  end

  context 'when a spelling suggestion exists even when results are present (https://github.com/elasticsearch/elasticsearch/issues/7472)' do
    before do
      result = { 'took' => 86, 'timed_out' => false, '_shards' => { 'total' => 2, 'successful' => 2, 'failed' => 0 }, 'hits' => { 'total' => 50, 'max_score' => 0.0, 'hits' => [] }, 'aggregations' => { 'album_agg' => { 'buckets' => [{ 'key' => '41555360@N03:2014-07-31:14794249441', 'doc_count' => 50, 'top_image_hits' => { 'hits' => { 'total' => 50, 'max_score' => 0.70445955, 'hits' => [{ '_index' => 'development-oasis-flickr_photos', '_type' => 'flickr_photo', '_id' => '14610842557', '_score' => 0.70445955, '_source' => { 'created_at' => '2014-09-02T18:00:36.525+00:00', 'updated_at' => '2014-09-13T18:42:12.145Z', 'owner' => '41555360@N03', 'groups' => %w[group1 group2], 'title' => 'President Obama Visits HUD', 'description' => '', 'taken_at' => '2014-07-31', 'tags' => %w[president potus barrackobama juliancastro sohud], 'url' => 'http://www.flickr.com/photos/41555360@N03/14610842557/', 'thumbnail_url' => 'https://farm4.staticflickr.com/3841/14610842557_ed0ff5879a_q.jpg', 'popularity' => 982, 'album' => '41555360@N03:2014-07-31:14794249441' } }] } }, 'top_score' => { 'value' => 0.704459547996521 } }] } }, 'suggest' => { 'suggestion' => [{ 'text' => 'president obama visits hud', 'offset' => 0, 'length' => 26, 'options' => [] }] } }
      expect(Elasticsearch::Persistence.client).to receive(:search).and_return(result)
    end

    it 'does not return a spelling suggestion' do
      image_search = described_class.new('accordion', {})
      image_search_results = image_search.search
      expect(image_search_results.suggestion).to be_nil
    end
  end

  context 'when there is some unforseen problem during the search' do
    it 'returns a no results response' do
      image_search = described_class.new('uh oh', {})
      expect(Elasticsearch::Persistence).to receive(:client).and_return(nil)
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(0)
      expect(image_search_results.results).to eq([])
    end
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
