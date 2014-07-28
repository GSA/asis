module TestServices
  extend self

  def create_es_indexes
    puts "Creating Elasticsearch test indexes...."
    Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
      klass = File.basename(f, '.*').camelize.constantize
      if klass.respond_to?(:create_index!)
        puts "     (Re)creating index #{klass.to_s}"
        klass.create_index!(force: true)
      end
    end
  end

  def delete_es_indexes
    Elasticsearch::Persistence.client.indices.delete(index: "test-oasis-*") rescue nil
  end

end
