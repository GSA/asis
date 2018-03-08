# frozen_string_literal: true

module API
  module V1
    class Base < Grape::API
      mount API::V1::InstagramProfiles
      mount API::V1::FlickrProfiles
      mount API::V1::MrssProfiles
      mount API::V1::ImageSearches
    end
  end
end
