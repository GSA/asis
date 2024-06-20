# frozen_string_literal: true

class TermsFilter
  def initialize(key, values)
    @key = key
    @values = values
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
        json.terms do
          json.set! @key, @values
        end
      end
    end
  end
end
