class ImageSearch
  IMAGE_INDEXES = [FlickrPhoto.index_name, InstagramPhoto.index_name].join(',')
  DEFAULT_SIZE = 10
  DEFAULT_FROM = 0
  DEFAULT_PRE_TAG = '<strong>'
  DEFAULT_POST_TAG = '</strong>'
  NO_HITS = { 'hits' => { 'total' => 0, 'offset' => 0, 'hits' => [] } }
  TEXT_FIELDS = %w(title description caption)

  def initialize(query, options)
    @query = (query || '').squish
    @size = options.delete(:size) || DEFAULT_SIZE
    @from = options.delete(:from) || DEFAULT_FROM
    @flickr_groups = normalize_profile_names(options.delete(:flickr_groups))
    @flickr_users = normalize_profile_names(options.delete(:flickr_users))
    @instagram_profiles = normalize_profile_names(options.delete(:instagram_profiles))
  end

  def search
    image_search_results = execute_client_search
    if image_search_results.total.zero? && image_search_results.suggestion.present?
      suggestion = image_search_results.suggestion
      @query = suggestion['text']
      image_search_results = execute_client_search
      image_search_results.override_suggestion(suggestion) if image_search_results.total > 0
    end
    image_search_results
  rescue Exception => e
    Rails.logger.error "Problem in ImageSearch#search(): #{e}"
    ImageSearchResults.new(NO_HITS)
  end

  private

  def execute_client_search
    params = { preference: '_local', index: IMAGE_INDEXES, body: query_body, from: @from, size: @size }
    result = Elasticsearch::Persistence.client.search(params)
    result['hits']['offset'] = @from
    ImageSearchResults.new(result)
  end

  def query_body
    Jbuilder.encode do |json|
      filtered_query(json)
      suggest(json)
    end
  end

  def normalize_profile_names(profile_names)
    profile_names.try(:collect) { |entry| entry.downcase }
  end

  def suggest(json)
    json.suggest do
      json.text @query
      json.suggestion do
        json.phrase do
          json.analyzer 'bigram_analyzer'
          json.field 'bigram'
          json.size 1
          json.direct_generator do
            json.child! do
              json.field 'bigram'
              json.prefix_len 1
            end
          end
          json.highlight do
            json.pre_tag pre_tags.first
            json.post_tag post_tags.first
          end
        end
      end
    end
  end

  def filtered_query(json)
    json.query do
      json.function_score do
        json.functions do
          json.child! do
            json.field_value_factor do
              json.field "popularity"
              json.modifier "log2p"
            end
          end
          json.child! do
            json.gauss do
              json.taken_at do
                json.scale "4w"
              end
            end
          end
        end
        json.query do
          json.filtered do
            filtered_query_query(json)
            filtered_query_filter(json)
          end
        end
      end
    end
  end

  def filtered_query_filter(json)
    json.filter do
      json.bool do
        json.set! :should do
          json.child! { flickr_profiles_filter(json, "group", @flickr_groups) } if @flickr_groups.present?
          json.child! { flickr_profiles_filter(json, "user", @flickr_users) } if @flickr_users.present?
          json.child! { instagram_profiles_filter(json, @instagram_profiles) } if @instagram_profiles.present?
        end
      end
    end if some_profile_specified?
  end

  def instagram_profiles_filter(json, profiles)
    json.bool do
      json.must do
        json.child! { json.terms { json.username profiles } }
        json.child! { json.term { json._type "instagram_photo" } }
      end
    end
  end

  def flickr_profiles_filter(json, profile_type, profiles)
    json.bool do
      json.must do
        json.child! { owner_terms(json, profiles) }
        json.child! { json.term { json.profile_type profile_type } }
        json.child! { json.term { json._type "flickr_photo" } }
      end
    end
  end

  def owner_terms(json, profiles)
    json.terms do
      json.owner profiles
    end
  end

  def filtered_query_query(json)
    json.query do
      json.bool do
        json.set! :should do
          json.child! { match_tags(json) }
          json.child! { simple_query_string(json) }
        end
      end
    end
  end

  def match_tags(json)
    json.match do
      json.tags do
        json.query @query
        json.analyzer "tag_analyzer"
      end
    end
  end

  def simple_query_string(json)
    json.simple_query_string do
      json.fields TEXT_FIELDS
      json.query @query
      json.analyzer "en_analyzer"
      json.default_operator "AND"
    end
  end

  def pre_tags
    [DEFAULT_PRE_TAG]
  end

  def post_tags
    [DEFAULT_POST_TAG]
  end

  def some_profile_specified?
    @flickr_groups.present? or @flickr_users.present? or @instagram_profiles.present?
  end

end