require Rails.root.join('app','parsers','mrss_parser.rb')
Feedjira::Feed.add_feed_class Feedjira::Parser::Oasis::Mrss