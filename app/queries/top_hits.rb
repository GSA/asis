class TopHits
  DEFAULT_PRE_TAG = '<strong>'
  DEFAULT_POST_TAG = '</strong>'
  TEXT_FIELDS = %w(title description caption)

  CUTOFF_FOR_DECAY = "now-6w/w"
  DECAY_SCALE = '4w'
  CUTOFF_BOOST_FACTOR = 0.119657286

  def initialize(query, size, from, flickr_groups, flickr_users, instagram_profiles)
    @query, @size, @from, @flickr_groups, @flickr_users, @instagram_profiles = query, size, from, flickr_groups, flickr_users, instagram_profiles
  end

  def query_body
    Jbuilder.encode do |json|
      filtered_query(json)
      aggs(json)
      suggest(json)
    end
  end

  def aggs(json)
    json.aggs do
      json.album_agg do
        json.terms do
          json.field "album"
          json.order do
            json.top_score "desc"
          end
          json.size @from + @size + 1
        end
        json.aggs do
          json.top_image_hits do
            json.top_hits do
              json.size 1
            end
          end
          json.top_score do
            json.max do
              json.script "_doc.score"
            end
          end
        end
      end
    end
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
          popularity_boost(json)
          recency_decay(json)
          older_photos(json)
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

  def older_photos(json)
    json.child! do
      json.filter do
        json.range do
          json.taken_at do
            json.lt CUTOFF_FOR_DECAY
          end
        end
      end
      json.boost_factor CUTOFF_BOOST_FACTOR
    end
  end

  def recency_decay(json)
    json.child! do
      json.filter do
        json.range do
          json.taken_at do
            json.gte CUTOFF_FOR_DECAY
          end
        end
      end
      json.gauss do
        json.taken_at do
          json.scale DECAY_SCALE
        end
      end
    end
  end

  def popularity_boost(json)
    json.child! do
      json.field_value_factor do
        json.field "popularity"
        json.modifier "log2p"
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