# frozen_string_literal: true

module ElasticSettings
  KEYWORD = { type: :keyword, normalizer: :case_insensitive_keyword_normalizer }.freeze
  TAG = { type: :text, analyzer: :tag_analyzer }.freeze

  # rubocop:disable Style/MutableConstant
  COMMON = {
    number_of_shards: Rails.configuration.elasticsearch['number_of_shards'],
    index: {
      analysis: {
        char_filter: {
          ignore_chars: { type: 'mapping', mappings: ["'=>", '’=>', '`=>'] },
          strip_whitespace: { type: 'mapping', mappings: ['\\u0020=>'] }
        },
        filter: {
          bigram_filter: { type: 'shingle' },
          en_stop_filter: { type: 'stop', stopwords: Rails.root.join('config/locales/analysis/en_stopwords.txt').readlines },
          en_synonym: { type: 'synonym', synonyms: Rails.root.join('config/locales/analysis/en_synonyms.txt').readlines.map(&:chomp) },
          en_protected_filter: { type: 'keyword_marker', keywords: Rails.root.join('config/locales/analysis/en_protwords.txt').readlines.map(&:chomp) },
          en_stem_filter: { type: 'stemmer', name: 'minimal_english' }
        },
        analyzer: {
          en_analyzer: {
            type: 'custom',
            tokenizer: 'standard',
            char_filter: %w[ignore_chars],
            filter: %w[asciifolding lowercase en_stop_filter en_protected_filter en_stem_filter en_synonym]
          },
          bigram_analyzer: {
            type: 'custom',
            tokenizer: 'standard',
            char_filter: %w[ignore_chars],
            filter: %w[asciifolding lowercase bigram_filter]
          },
          tag_analyzer: {
            type: 'custom',
            tokenizer: 'standard',
            char_filter: %w[strip_whitespace],
            filter: %w[asciifolding lowercase]
          }
        },
        normalizer: {
          case_insensitive_keyword_normalizer: {
            type: 'custom',
            char_filter: %w[ignore_chars],
            filter: %w[asciifolding lowercase]
          }
        }
      }
    }
    # rubocop:enable Style/MutableConstant
  }
end
