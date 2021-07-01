# frozen_string_literal: true

module Api
  module V1
    class FlickrProfiles < Grape::API
      version 'v1'
      format :json

      resource :flickr_profiles do
        desc 'Return list of indexed Flickr profiles'
        get do
          FlickrProfile.all(sort: :name)
        end

        desc 'Create a Flickr profile and enqueue backfilling photos.'
        params do
          requires :id, type: String, desc: 'Flickr profile id.'
          requires :name, type: String, desc: 'Flickr profile name.'
          requires :profile_type, type: String, desc: 'Flickr profile type (user|group).'
        end
        post do
          flickr_profile = FlickrProfile.new(name: params[:name], id: params[:id], profile_type: params[:profile_type])
          flickr_profile.save && FlickrPhotosImporter.perform_async(flickr_profile.id, flickr_profile.profile_type)
          flickr_profile
        end
      end
    end
  end
end
