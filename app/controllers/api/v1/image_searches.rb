# frozen_string_literal: true

module Api
  module V1
    class ImageSearches < Grape::API
      version 'v1'
      format :json

      resource :image do
        desc 'Return image search results'

        params do
          requires :query, type: String, desc: 'query term'
          optional :size, type: Integer, desc: 'number of results (defaults to 10)'
          optional :from, type: Integer, desc: 'starting result (defaults to 0)'
          optional :flickr_groups, type: String, desc: 'restrict results to these Flickr groups (comma separated)'
          optional :flickr_users, type: String, desc: 'restrict results to these Flickr users (comma separated)'
          optional :instagram_profiles, type: String, desc: 'restrict results to these Instagram profiles (comma separated)'
          optional :mrss_names, type: String, desc: 'restrict results to these MRSS names (comma separated)'
        end

        get do
          image_search = ImageSearch.new(params[:query], size: params[:size], from: params[:from],
                                                         flickr_groups: params[:flickr_groups].try(:split, ','),
                                                         flickr_users: params[:flickr_users].try(:split, ','),
                                                         mrss_names: params[:mrss_names].try(:split, ','),
                                                         instagram_profiles: params[:instagram_profiles].try(:split, ','))
          image_search.search
        end
      end
    end
  end
end
