require 'flickraw'
FlickRaw.api_key = Rails.configuration.flickr['api_key']
FlickRaw.shared_secret = Rails.configuration.flickr['shared_secret']
