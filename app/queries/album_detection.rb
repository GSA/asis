# frozen_string_literal: true

class AlbumDetection
  def initialize(photo, query_fields_thresholds_hash, filter_fields)
    @photo = photo
    @query_fields_thresholds_hash = query_fields_thresholds_hash
    @filter_fields = filter_fields
  end

  def query_body
    Jbuilder.encode do |json|
      filtered_query(json)
      aggregations(json)
    end
  end

  private

  def filtered_query(json)
    json.query do
      json.bool do
        filtered_query_query(json)
        filtered_query_filter(json)
      end
    end
  end

  def filtered_query_filter(json)
    json.filter do
      json.bool do
        json.must do
          @filter_fields.each do |filter_field|
            term_filter_child(json, filter_field)
          end
        end
      end
    end
  end

  def filtered_query_query(json)
    json.must do
      @query_fields_thresholds_hash.each do |query_field, minimum_should_match|
        more_like_this(json, query_field, minimum_should_match)
      end
    end
  end

  # https://www.elastic.co/guide/en/elasticsearch/reference/2.0/breaking_20_query_dsl_changes.html#_more_like_this
  def more_like_this(json, query_field, minimum_should_match)
    return if @photo.send(query_field).blank?
    json.child! do
      json.more_like_this do
        json.fields [query_field]
        json.like [{ _id: @photo.id }]
        json.min_term_freq 1
        json.max_query_terms 500
        json.minimum_should_match percentize(minimum_should_match)
      end
    end
  end

  def term_filter_child(json, filter_field)
    filter_value = @photo.send(filter_field)
    return if filter_value.blank?
    json.child! do
      if filter_value.is_a? Array
        json.terms do
          json.set! filter_field, filter_value
        end
      else
        json.term do
          json.set! filter_field, filter_value
        end
      end
    end
  end

  def aggregations(json)
    json.aggregations do
      json.scores_histogram do
        json.histogram do
          json.script do
            json.source '_score'
            json.lang 'painless'
          end
          json.interval 2
          json.order do
            json._key 'desc'
          end
        end
      end
    end
  end

  def percentize(number)
    "#{(number * 100).round}%"
  end
end
