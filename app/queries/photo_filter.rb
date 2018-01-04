class PhotoFilter
  def initialize(key, value)
    @key, @value = key, value
  end

  def query_body
    builder = Jbuilder.new do |json|
      filtered_query(json)
    end
    builder.attributes!
  end

  private
  def filtered_query(json)
    json.bool do
      json.filter do
        json.term do
          json.set! @key, @value
        end
      end
    end
  end

end
