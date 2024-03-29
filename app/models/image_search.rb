# frozen_string_literal: true

class ImageSearch
  IMAGE_INDEXES = [FlickrPhoto.index_name, MrssPhoto.index_name].join(',')
  DEFAULT_SIZE = 10
  DEFAULT_FROM = 0
  NO_HITS = { 'hits' => { 'total' => 0, 'max_score' => 0.0, 'hits' => [] }, 'aggregations' => { 'album_agg' => { 'buckets' => [] } } }.freeze

  def initialize(query, options)
    @query = (query || '').squish
    @size = options.delete(:size) || DEFAULT_SIZE
    @from = options.delete(:from) || DEFAULT_FROM
    @flickr_groups = normalize_profile_names(options.delete(:flickr_groups))
    @flickr_users = normalize_profile_names(options.delete(:flickr_users))
    @mrss_names = normalize_profile_names(options.delete(:mrss_names))
  end

  def search
    image_search_results = execute_client_search
    ensure_no_suggestion_when_results_present(image_search_results)
    if image_search_results.total.zero? && image_search_results.suggestion.present?
      suggestion = image_search_results.suggestion
      @query = suggestion['text']
      image_search_results = execute_client_search
      image_search_results.override_suggestion(suggestion) if image_search_results.total.positive?
    end
    image_search_results
  rescue StandardError => e
    Rails.logger.error "Problem in ImageSearch#search(): #{e}"
    ImageSearchResults.new(NO_HITS)
  end

  private

  def ensure_no_suggestion_when_results_present(image_search_results)
    image_search_results.override_suggestion(nil) if image_search_results.total.positive? && image_search_results.suggestion.present?
  end

  def execute_client_search
    top_hits_query = TopHits.new(@query, @size, @from, @flickr_groups, @flickr_users, @mrss_names)
    # https://www.elastic.co/guide/en/elasticsearch/reference/5.5/breaking_50_search_changes.html#_literal_search_type_count_literal_removed
    params = { preference: '_local', index: IMAGE_INDEXES, body: top_hits_query.query_body(search_type: :count) }
    result = Elasticsearch::Persistence.client.search(params)
    ImageSearchResults.new(result, @from, @size)
  end

  def normalize_profile_names(profile_names)
    profile_names.try(:collect, &:downcase)
  end
end
