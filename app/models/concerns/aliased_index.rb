# frozen_string_literal: true

module AliasedIndex
  extend ActiveSupport::Concern

  included do
    index_name alias_name
  end

  module ClassMethods
    def timestamped_index_name
      [base_name, Time.current.to_s].join('-')
    end

    def alias_name
      [base_name, 'alias'].join('-')
    end

    def base_name
      [Rails.env, Rails.application.engine_name.split('_').first, name.tableize].join('-')
    end

    def create_index_and_alias!
      current_name = timestamped_index_name
      # We *should* be able to simplify this as: `create_index!(index: current_name)`.
      # However, elasticsearch-model 5.x does not support the include_type_name option,
      # which is necessary for compatibility with Elasticsearch 7.x. Until our gems
      # are upgraded, we're using a more verbose request via the client:
      Elasticsearch::Persistence.client.indices.create(
        index: current_name,
        body: {
          mappings: mappings,
          settings: settings
        },
        include_type_name: true
      )
      create_index!(index: current_name)
      Elasticsearch::Persistence.client.indices.put_alias(index: current_name, name: alias_name)
    end

    def alias_exists?
      Elasticsearch::Persistence.client.indices.get_alias(name: alias_name).keys.present?
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      false
    end

    # For use in test and development environments. Purging existing indices is
    # significantly faster than deleting and recreating them.
    def delete_all
      refresh_index!
      Elasticsearch::Persistence.client.delete_by_query(
        index: alias_name,
        conflicts: :proceed,
        body: { query: { match_all: {} } }
      )
    end
  end
end
