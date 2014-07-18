require 'flickraw'
yaml = YAML.load_file("#{Rails.root}/config/flickr.yml")
FlickRaw.api_key = yaml['api_key']
FlickRaw.shared_secret = yaml['shared_secret']