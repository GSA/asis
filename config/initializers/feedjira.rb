require Rails.root.join('app','parsers','mrss_entry.rb')
require Rails.root.join('app','parsers','mrss.rb')
Feedjira::Feed.add_feed_class Feedjira::Parser::Oasis::Mrss