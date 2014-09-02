class AlbumDetection
  def initialize(photo, query_fields_thresholds_hash, filter_fields)
    @photo, @query_fields_thresholds_hash, @filter_fields = photo, query_fields_thresholds_hash, filter_fields
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
      json.filtered do
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
    json.query do
      json.bool do
        json.must do
          @query_fields_thresholds_hash.each do |query_field, minimum_should_match|
            more_like_this(json, query_field, minimum_should_match)
          end
        end
      end
    end
  end

  def more_like_this(json, query_field, minimum_should_match)
    json.child! do
      json.more_like_this do
        json.fields [query_field]
        json.ids [@photo.id]
        json.min_term_freq 1
        json.max_query_terms 500
        json.percent_terms_to_match minimum_should_match
      end
    end if @photo.send(query_field).present?
  end

  def term_filter_child(json, filter_field)
    json.child! do
      json.term do
        json.set! filter_field, @photo.send(filter_field)
      end
    end
  end

  def aggregations(json)
    json.aggregations do
      json.scores_histogram do
        json.histogram do
          json.script "doc.score"
          json.interval 2
          json.order do
            json._key "desc"
          end
        end
      end
    end
  end


end