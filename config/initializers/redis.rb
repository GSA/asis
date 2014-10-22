yaml = YAML.load_file("#{Rails.root}/config/sidekiq.yml")
$redis = Redis.new(url: yaml['url'], namespace: yaml['namespace'])
