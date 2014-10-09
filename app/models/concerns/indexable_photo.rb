module IndexablePhoto
  extend ActiveSupport::Concern
  include AliasedIndex

  included do

    settings ElasticSettings::COMMON do
      mappings dynamic: 'false' do
        indexes :bigram, analyzer: 'bigram_analyzer', type: 'string'
      end
    end
    attribute :taken_at, Date
    attribute :tags, String, mapping: ElasticSettings::TAG
    attribute :url, String, mapping: ElasticSettings::KEYWORD
    attribute :thumbnail_url, String, mapping: ElasticSettings::KEYWORD
    attribute :popularity, Integer, default: 0, mapping: { type: 'integer', index: :not_analyzed }
    attribute :album, String, mapping: { type: 'string', index: :not_analyzed }

    validates :url, presence: true
    validates :thumbnail_url, presence: true
    validates :taken_at, presence: true

  end
end