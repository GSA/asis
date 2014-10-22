require 'rails_helper'

describe MrssProfile do
  it_behaves_like "a model with an aliased index name"

  describe "#mrss_urls_from_names(mrss_names)" do
    context 'when mrss_names present' do
      before do
        MrssProfile.create(id: 'http://some/mrss.url/feed.xml1', name: '1')
        MrssProfile.create(id: 'http://some/mrss.url/feed.xml2', name: '2')
        MrssProfile.create(id: 'http://some/mrss.url/feed.xml3', name: '3')
        MrssProfile.refresh_index!
      end

      it 'should return the IDs (feed urls) from the records' do
        expect(MrssProfile.mrss_urls_from_names(%w(1 3))).to match_array(%w(http://some/mrss.url/feed.xml1 http://some/mrss.url/feed.xml3))
      end
    end
  end
end