# frozen_string_literal: true

class ImageSearchResults
  attr_reader :total, :offset, :results, :suggestion

  Image = Struct.new(:type, :title, :url, :thumbnail_url, :taken_at)

  def initialize(result, offset = 0, window_size = 0)
    @total = result['aggregations']['album_agg']['buckets'].size
    @offset = offset
    @results = extract_results(extract_hits(result['aggregations']['album_agg']['buckets'].slice(offset, window_size)))
    @suggestion = extract_suggestion(result['suggest']['suggestion']) if result['suggest']
  end

  def override_suggestion(suggestion)
    @suggestion = suggestion
  end

  private

  def extract_suggestion(suggestions)
    suggestion = suggestions.first['options'].first
    suggestion.delete('score')
    suggestion
  rescue NoMethodError
    nil
  end

  def extract_hits(buckets)
    buckets.map do |bucket|
      bucket['top_image_hits']['hits']['hits']
    end.flatten
  end

  def extract_results(hits)
    hits.map do |hit|
      type = hit['_type'].camelize
      Image.new(type, extract_title(type, hit), hit['_source']['url'], hit['_source']['thumbnail_url'], hit['_source']['taken_at'])
    end
  end

  def extract_title(type, hit)
    type == 'InstagramPhoto' ? hit['_source']['caption'] : hit['_source']['title']
  end
end
