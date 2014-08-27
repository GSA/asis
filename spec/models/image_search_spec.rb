require 'rails_helper'

describe ImageSearch do

  context 'when relevant results exist in both Instagram and Flickr indexes' do
    before do
      FlickrPhoto.create(id: "photo1", owner: "owner1", profile_type: 'user', tags: [], title: "title1 earth", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1")
      FlickrPhoto.refresh_index!
      InstagramPhoto.create(id: "123456", username: 'user1', tags: %w(tag1 tag2), caption: 'first photo of earth', taken_at: Date.current, popularity: 101, url: "http://photo2", thumbnail_url: "http://photo_thumbnail2")
      InstagramPhoto.refresh_index!
    end

    it 'should return results from both indexes' do
      image_search = ImageSearch.new("earth", {})
      image_search_results = image_search.search
      expect(image_search_results.results.collect(&:type).uniq).to match_array(["InstagramPhoto", "FlickrPhoto"])
    end
  end

  context 'when smooshed user query matches tag in either Instagram or Flickr indexes' do
    before do
      FlickrPhoto.create(id: "photo1", owner: "owner1", profile_type: 'user', tags: %w(apollo11 space), title: "title1 earth", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1")
      FlickrPhoto.refresh_index!
      InstagramPhoto.create(id: "123456", username: 'user1', tags: %w(earth apollo11), caption: 'first photo of earth', taken_at: Date.current, popularity: 101, url: "http://photo2", thumbnail_url: "http://photo_thumbnail2")
      InstagramPhoto.refresh_index!
    end

    it 'should return results from both indexes' do
      image_search = ImageSearch.new("apollo 11", {})
      image_search_results = image_search.search
      expect(image_search_results.results.collect(&:type).uniq).to match_array(["InstagramPhoto", "FlickrPhoto"])
    end
  end

  context 'when search term yields no results but a similar spelling does have results' do
    before do
      FlickrPhoto.create(id: "photo1", owner: "owner1", profile_type: 'user', tags: [], title: "title1 earth", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1")
      InstagramPhoto.create(id: "123456", username: 'user1', tags: %w(tag1 tag2), caption: 'photo of the cassini probe', taken_at: Date.current, popularity: 101, url: "http://photo2", thumbnail_url: "http://photo_thumbnail2")
      InstagramPhoto.refresh_index!
      FlickrPhoto.refresh_index!
    end

    it 'should return results for the close spelling' do
      image_search = ImageSearch.new("casini", {})
      image_search_results = image_search.search
      expect(image_search_results.results.first.title).to eq('photo of the cassini probe')
      expect(image_search_results.suggestion['text']).to eq('cassini')
      expect(image_search_results.suggestion['highlighted']).to eq('<strong>cassini</strong>')
    end
  end

  context 'when a spelling suggestion exists even when results are present (https://github.com/elasticsearch/elasticsearch/issues/7472)' do
    before do
      result = { "took" => 6, "timed_out" => false, "_shards" => { "total" => 10, "successful" => 10, "failed" => 0 },
                 "hits" => { "total" => 7472, "max_score" => 4.840977, "hits" =>
                   [{ "_index" => "development-oasis-flickr_photos", "_type" => "flickr_photo", "_id" => "14610730228",
                      "_score" => 4.840977,
                      "_source" => { "created_at" => "2014-08-19T17:46:27.194+00:00", "updated_at" => "2014-08-19T17:46:27.194+00:00",
                                     "owner" => "41555360@N03", "profile_type" => "user", "title" => "President Obama Visits HUD", "description" => "",
                                     "taken_at" => "2014-07-31", "tags" => ["president", "potus", "barrackobama", "juliancastro", "sohud"],
                                     "url" => "http://www.flickr.com/photos/41555360@N03/14610730228/",
                                     "thumbnail_url" => "https://farm6.staticflickr.com/5595/14610730228_59c8b84fb8_q.jpg", "popularity" => 888 } }] },
                 "suggest" => { "suggestion" => [{ "text" => "accordion", "offset" => 0, "length" => 9, "options" =>
                   [{ "text" => "according", "highlighted" => "<strong>according</strong>", "score" => 0.061992195 }] }] } }
      expect(Elasticsearch::Persistence.client).to receive(:search).and_return(result)
    end

    it 'should not return a spelling suggestion' do
      image_search = ImageSearch.new("accordion", {})
      image_search_results = image_search.search
      expect(image_search_results.suggestion).to be_nil
    end
  end

  context 'when there is some unforseen problem during the search' do
    it 'should return a no results response' do
      image_search = ImageSearch.new("uh oh", {})
      expect(Elasticsearch::Persistence).to receive(:client).and_return(nil)
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(0)
      expect(image_search_results.results).to eq([])
    end
  end

  describe "filtering on flickr/instagram profiles" do
    before do
      FlickrPhoto.create(id: "photo1", owner: "owner1", profile_type: 'user', tags: [], title: "title1 earth", description: "desc 1", taken_at: Date.current, popularity: 100, url: "http://photo1", thumbnail_url: "http://photo_thumbnail1")
      FlickrPhoto.create(id: "photo2", owner: "owner2", profile_type: 'group', tags: [], title: "title2 earth", description: "desc 2", taken_at: Date.current, popularity: 100, url: "http://photo2", thumbnail_url: "http://photo_thumbnail2")
      InstagramPhoto.create(id: "123456", username: 'user1', tags: %w(tag1 tag2), caption: 'first photo of earth', taken_at: Date.current, popularity: 101, url: "http://instaphoto2", thumbnail_url: "http://instaphoto_thumbnail2")
      InstagramPhoto.refresh_index!
      FlickrPhoto.refresh_index!
    end

    it "should filter on flickr users" do
      image_search = ImageSearch.new("earth", { flickr_users: ["owner1"] })
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('title1 earth')
    end

    it "should filter on flickr groups" do
      image_search = ImageSearch.new("earth", { flickr_groups: ["owner2"] })
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('title2 earth')
    end

    it "should filter on instagram profiles" do
      image_search = ImageSearch.new("earth", { instagram_profiles: ["user1"] })
      image_search_results = image_search.search
      expect(image_search_results.total).to eq(1)
      expect(image_search_results.results.first.title).to eq('first photo of earth')
    end
  end
end