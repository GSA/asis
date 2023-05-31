# frozen_string_literal: true

yaml = YAML.load_file("#{Rails.root}/config/sidekiq.yml")

# rubocop:disable Style/GlobalVars
$redis = Redis.new(url: yaml['url'], namespace: yaml['namespace'])
# rubocop:enable Style/GlobalVars
