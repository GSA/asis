# frozen_string_literal: true

require 'rails_helper'

describe Feedjira::Parser::Oasis::Mrss do
  context 'for DMA feed' do
    let(:dma_mrss_xml) { file_fixture('dma.xml').read }

    describe '#able_to_parse?' do
      context 'when first 2000 chars of XML contains MRSS text string' do
        it 'returns true' do
          expect(described_class.able_to_parse?(dma_mrss_xml)).to be_truthy
        end
      end
    end

    describe 'the parser' do
      it 'pulls out the entries properly' do
        feed = Feedjira::Feed.parse(dma_mrss_xml)
        expect(feed.entries.first.class).to eq(Feedjira::Parser::Oasis::MrssEntry)
      end
    end
  end

  context 'for RSS with content module' do
    let(:mrss_xml) { file_fixture('rss_with_content_module.xml').read }

    describe '#able_to_parse?' do
      context 'when first 2000 chars of XML contains the content namespace text string' do
        it 'returns true' do
          expect(described_class.able_to_parse?(mrss_xml)).to be_truthy
        end
      end
    end

    describe 'the parser' do
      it 'pulls out the entries properly' do
        feed = Feedjira::Feed.parse(mrss_xml)
        expect(feed.entries.first.class).to eq(Feedjira::Parser::Oasis::MrssEntry)
      end
    end
  end
end
