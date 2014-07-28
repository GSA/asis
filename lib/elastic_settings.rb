module ElasticSettings
  KEYWORD = { type: 'string', analyzer: 'case_insensitive_keyword_analyzer' }
  ENGLISH_STOPWORDS = %w(a an and are as at be but by for if in into is no not of on or s such t that the their then there these they this to was with)

  COMMON = {
    index: {
      number_of_shards: 1,
      analysis: {
        char_filter: {
          ignore_chars: { type: "mapping", mappings: ["'=>", "’=>", "`=>"] }
        },
        filter: {
          bigram_filter: { type: 'shingle' },
          en_stop_filter: { type: "stop", stopwords: ENGLISH_STOPWORDS },
          en_synonym: { type: 'synonym', synonyms: File.readlines(Rails.root.join("config", "locales", "analysis", "en_synonyms.txt")) },
          en_stem_filter: { type: "stemmer", name: "minimal_english" }
        },
        analyzer: {
          en_analyzer: {
            type: "custom",
            tokenizer: "standard",
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase en_stop_filter en_stem_filter en_synonym) },
          bigram_analyzer: {
            type: "custom",
            tokenizer: "standard",
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase bigram_filter)
          },
          case_insensitive_keyword_analyzer: {
            tokenizer: 'keyword',
            char_filter: %w(ignore_chars),
            filter: %w(standard asciifolding lowercase) } } } }
  }

end
