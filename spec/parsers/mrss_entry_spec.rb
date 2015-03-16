require 'rails_helper'

describe Feedjira::Parser::Oasis::MrssEntry do
  context 'when entry has media:thumbnail and media:description' do
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

  context 'when entry has description and media:description' do
    let(:entries) do
      mrss_xml = File.read(Rails.root.to_s + '/spec/sample_feeds/desc_plus_mediadesc.xml')
      feed = Feedjira::Feed.parse(mrss_xml)
      feed.entries
    end

    describe 'a parsed entry' do
      it 'should use whatever comes last in the XML' do
        expect(entries.first.summary).to eq("This came from description")
        expect(entries.last.summary).to eq("But this came from media:description")
      end
    end
  end

  context 'when the feed uses RSS content module' do
    let(:entry) do
      mrss_xml = File.read(Rails.root.to_s + '/spec/sample_feeds/rss_with_content_module.xml')
      feed = Feedjira::Feed.parse(mrss_xml)
      feed.entries.first
    end

    describe 'a parsed entry' do
      it 'should use the content:encoded field for the summary' do
        expect(entry.summary).to eq("Sentence one. Sentence two. more...")
      end
    end
  end

  context 'when URLs are missing scheme' do
    let(:entry) do
      mrss_xml = File.read(Rails.root.to_s + '/spec/sample_feeds/missing_scheme.xml')
      feed = Feedjira::Feed.parse(mrss_xml)
      feed.entries.first
    end

    it 'should prepend with http' do
      expect(entry.url).to eq("http://www.af.mil/News/Photos.aspx?igphoto=2000949217")
      expect(entry.thumbnail_url).to eq("http://media.dma.mil/2014/Oct/22/2000949217/145/100/0/141022-F-PB123-223.JPG")
    end
  end

end