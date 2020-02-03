# frozen_string_literal: true

module AliasedIndex
  extend ActiveSupport::Concern

  included do
    index_name alias_name
  end

  module ClassMethods
    def timestamped_index_name
      [base_name, Time.now.to_s(:number)].join('-')
    end

    def alias_name
      [base_name, 'alias'].join('-')
    end

    def base_name
      [Rails.env, Rails.application.engine_name.split('_').first, name.tableize].join('-')
    end

    def create_index_and_alias!
      current_name = timestamped_index_name
      create_index!(index: current_name)
      Elasticsearch::Persistence.client.indices.put_alias index: current_name, name: alias_name
    end

    def alias_exists?
      Elasticsearch::Persistence.client.indices.get_alias(name: alias_name).keys.present?
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      false
    end

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
