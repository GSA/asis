# frozen_string_literal: true

module Api
  module V1
    class MrssProfiles < Grape::API
      version 'v1'
      format :json

      resource :mrss_profiles do
        desc 'Return list of indexed MRSS profiles ordered by created_at timestamp'
        get do
          MrssProfile.all(sort: :created_at)
        end

        desc 'Create an MRSS profile and enqueue backfilling photos.'
        params do
          requires :url, type: String, desc: 'MRSS feed URL.'
        end
        post do
          profile = MrssProfile.create_or_find_by_id(params[:url])
          if profile.persisted?
            MrssProfile.refresh_index!
            MrssPhotosImporter.perform_async(profile.name)
            profile
          end
        end
      end
    end
  end
end
