yaml = YAML.load_file("#{Rails.root}/config/airbrake.yml")

Airbrake.configure do |config|
  config.api_key = yaml['api_key']
end
