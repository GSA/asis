# frozen_string_literal: true

module Api
  module V1
    class Base < Grape::API
      mount Api::V1::InstagramProfiles
      mount Api::V1::FlickrProfiles
      mount Api::V1::MrssProfiles
      mount Api::V1::ImageSearches
    end
  end
end
