require 'rails_helper'

describe Feedjira::Parser::Oasis::Mrss do
  let(:dma_mrss_xml) { File.read(Rails.root.to_s + '/spec/sample_feeds/dma.xml') }

  describe '#able_to_parse?' do
    context 'when first 2000 chars of XML contains MRSS text string' do
      it 'should return true' do
        expect(Feedjira::Parser::Oasis::Mrss.able_to_parse?(dma_mrss_xml)).to be_truthy
      end
    end
  end

  describe 'the parser' do
    it 'should pull out the entries properly' do
      feed = Feedjira::Feed.parse(dma_mrss_xml)
      expect(feed.entries.first.class).to eq(Feedjira::Parser::Oasis::MrssEntry)
    end
  end
end

describe Feedjira::Parser::Oasis::MrssEntry do
  let(:entry) do
    dma_mrss_xml = File.read(Rails.root.to_s + '/spec/sample_feeds/dma.xml')
    feed = Feedjira::Feed.parse(dma_mrss_xml)
    feed.entries.first
  end

  describe 'a parsed entry' do
    it 'should have the correct title stripped and squished' do
      expect(entry.title).to eq("")
    end
    it 'should have the correct summary stripped and squished' do
      expect(entry.summary).to eq("Official Photo- of something important (U.S. Air Force Photo)")
    end
    it 'should have the correct url' do
      expect(entry.url).to eq("http://www.af.mil/News/Photos.aspx?igphoto=2000949217")
    end
    it 'should have the correct thumbnail url' do
      expect(entry.thumbnail_url).to eq("http://media.dma.mil/2014/Oct/22/2000949217/145/100/0/141022-F-PB123-223.JPG")
    end
    it 'should have the correct entry_id' do
      expect(entry.entry_id).to eq("http://www.af.mil/News/Photos.aspx?igphoto=2000949217")
    end
    it 'should have the correct published time' do
      expect(entry.published).to eq(Time.parse("2014-10-22 14:24:00Z"))
    end
  end
end