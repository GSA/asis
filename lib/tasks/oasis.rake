require 'csv'
namespace :oasis do
  desc "Create initial batch of Flickr and Instagram profiles from CSV files"
  task :seed_profiles => :environment do
    CSV.foreach("#{Rails.root}/config/flickr_profiles.csv") do |row|
      flickr_profile = FlickrProfile.new(name: row[2], id: row[1], profile_type: row[0])
      flickr_profile.save and FlickrPhotosImporter.perform_async(flickr_profile.id, flickr_profile.profile_type)
    end
    CSV.foreach("#{Rails.root}/config/instagram_profiles.csv") do |row|
      instagram_profile = InstagramProfile.new(username: row[1], id: row[0])
      instagram_profile.save and InstagramPhotosImporter.perform_async(instagram_profile.id)
    end
    CSV.foreach("#{Rails.root}/config/mrss_profiles.csv") do |row|
      mrss_profile = MrssProfile.new(id: row[0])
      mrss_profile.save and MrssPhotosImporter.perform_async(mrss_profile.name)
    end
  end
end
