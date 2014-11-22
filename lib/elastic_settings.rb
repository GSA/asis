module ElasticSettings
  KEYWORD = { type: 'string', analyzer: 'case_insensitive_keyword_analyzer' }
  TAG = { type: 'string', analyzer: 'tag_analyzer' }

  COMMON = {
    index: {
      analysis: {
        char_filter: {
          ignore_chars: { type: "mapping", mappings: ["'=>", "’=>", "`=>"] },
          strip_whitespace: { type: "mapping", mappings: ["\\u0020=>"] }
        },
        filter: {
          bigram_filter: { type: 'shingle' },
          en_stop_filter: { type: "stop", stopwords: File.readlines(Rails.root.join("config", "locales", "analysis", "en_stopwords.txt")) },
          en_synonym: { type: 'synonym', synonyms: File.readlines(Rails.root.join("config", "locales", "analysis", "en_synonyms.txt")).map(&:chomp) },
          en_protected_filter: { type: 'keyword_marker', keywords: File.readlines(Rails.root.join("config", "locales", "analysis", "en_protwords.txt")).map(&:chomp) },
          en_stem_filter: { type: "stemmer", name: "minimal_english" }
        },
        analyzer: {
          en_analyzer: {
            type: "custom",
            tokenizer: "standard",
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase en_stop_filter en_protected_filter en_stem_filter en_synonym) },
          bigram_analyzer: {
            type: "custom",
            tokenizer: "standard",
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase bigram_filter)
          },
          tag_analyzer: {
            type: "custom",
            tokenizer: "standard",
            char_filter: %w(strip_whitespace),
            filter: %w(standard asciifolding lowercase)
          },
          case_insensitive_keyword_analyzer: {
            tokenizer: 'keyword',
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase) } } } }
  }

end
