module TestServices
  extend self

  def create_es_indexes
    puts "Creating Elasticsearch test indexes...."
    puts "#{Rails.env}-oasis-flickr_photos before create:"
    begin
      puts Elasticsearch::Persistence.client.indices.get_mapping(index: "#{Rails.env}-oasis-flickr_photos")
      puts Elasticsearch::Persistence.client.indices.get_settings(index: "#{Rails.env}-oasis-flickr_photos")
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => i
      puts "#{Rails.env}-oasis-flickr_photos does not yet exist"
    end
    Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
      klass = File.basename(f, '.*').camelize.constantize
      if klass.respond_to?(:create_index!)
        puts "     (Re)creating index #{klass.to_s}"
        klass.create_index!(force: true)
      end
    end
    puts "#{Rails.env}-oasis-flickr_photos mapping after create:"
    puts Elasticsearch::Persistence.client.indices.get_mapping(index: "#{Rails.env}-oasis-flickr_photos")
    puts "Settings:"
    puts Elasticsearch::Persistence.client.indices.get_settings(index: "#{Rails.env}-oasis-flickr_photos")
  end

  def delete_es_indexes
    Elasticsearch::Persistence.client.indices.delete(index: "test-oasis-*") rescue nil
  end

end
