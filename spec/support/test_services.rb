module TestServices
  extend self

  def create_es_indexes
    Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
      klass = File.basename(f, '.*').camelize.constantize
      klass.create_index_and_alias! if klass.respond_to?(:create_index_and_alias!)
    end
  end

  def delete_es_indexes
    Elasticsearch::Persistence.client.indices.delete(index: "test-oasis-*") rescue nil
  end

end
