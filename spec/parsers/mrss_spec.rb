require 'rails_helper'

describe Feedjira::Parser::Oasis::Mrss do
  context 'for DMA feed' do
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

  context 'for RSS with content module' do
    let(:mrss_xml) { File.read(Rails.root.to_s + '/spec/sample_feeds/rss_with_content_module.xml') }

    describe '#able_to_parse?' do
      context 'when first 2000 chars of XML contains the content namespace text string' do
        it 'should return true' do
          expect(Feedjira::Parser::Oasis::Mrss.able_to_parse?(mrss_xml)).to be_truthy
        end
      end
    end

    describe 'the parser' do
      it 'should pull out the entries properly' do
        feed = Feedjira::Feed.parse(mrss_xml)
        expect(feed.entries.first.class).to eq(Feedjira::Parser::Oasis::MrssEntry)
      end
    end
  end

end
