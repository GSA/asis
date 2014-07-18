require 'rails_helper'

describe API::V1::ImageSearches do
  describe "GET /api/v1/image_searches" do
    context 'when all params passed in' do
      let(:image_search) { double(ImageSearch) }
      let(:search_results) { Hashie::Mash.new({"total"=>1, "offset"=>0, "results"=>[{"type"=>"InstagramPhoto", "title"=>"title", "url"=>"http://instagram.com/p/efykKOIaCh/", "thumbnail_url"=>"http://scontent-b.cdninstagram.com/hphotos-xpf1/outbound-distilleryimage9/t0.0-17/OBPTH/9c929416223811e3bad522000ab5bccf_5.jpg", "taken_at"=>"2013-09-20"}], "suggestion"=>{"text"=>"cindy", "highlighted"=>"<strong>cindy</strong>"}} ) }
      before do
        expect(ImageSearch).to receive(:new).with("some query", { size: 11, from: 10, flickr_groups: ["fg1", "fg2"], flickr_users: ["fu1", "fu2"], instagram_profiles: ["ip1"] }).and_return(image_search)
      end

      it "performs the search with the appropriate params" do
        expect(image_search).to receive(:search) { search_results }
        get "/api/v1/image", query: "some query", size: 11, from: 10, flickr_groups: "fg1,fg2", flickr_users: "fu1,fu2", instagram_profiles: "ip1"
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to match(hash_including({"total"=>1, "offset"=>0, "results"=>[{"type"=>"InstagramPhoto", "title"=>"title", "url"=>"http://instagram.com/p/efykKOIaCh/", "thumbnail_url"=>"http://scontent-b.cdninstagram.com/hphotos-xpf1/outbound-distilleryimage9/t0.0-17/OBPTH/9c929416223811e3bad522000ab5bccf_5.jpg", "taken_at"=>"2013-09-20"}], "suggestion"=>{"text"=>"cindy", "highlighted"=>"<strong>cindy</strong>"}}))
      end
    end
  end

end