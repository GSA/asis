# frozen_string_literal: true

module Api
  class Base < Grape::API
    rescue_from :all do |e|
      Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"

      Airbrake.notify(e)

      Rack::Response.new({ message: e.message, backtrace: e.backtrace }, 500, 'Content-type' => 'application/json').finish
    end

    mount Api::V1::Base
  end
end
