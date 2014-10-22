module API
  module V1
    class MrssProfiles < Grape::API
      version 'v1'
      format :json

      resource :mrss_profiles do
        desc "Return list of indexed MRSS profiles ordered by created_at timestamp"
        get do
          MrssProfile.all(sort: :created_at)
        end

        desc "Create an MRSS profile and enqueue backfilling photos."
        params do
          requires :url, type: String, desc: "MRSS feed URL."
        end
        post do
          profile = begin
            mrss_profile = MrssProfile.new(id: params[:url])
            mrss_profile.save(op_type: 'create') and MrssPhotosImporter.perform_async(mrss_profile.id)
            mrss_profile
          rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
            MrssProfile.find(params[:url])
          end
          profile
        end
      end
    end
  end
end