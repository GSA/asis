# frozen_string_literal: true

module Feedjira
  module Parser
    module Oasis
      class Mrss
        include SAXMachine
        include FeedUtilities

        element :title
        element :link
        element :description

        elements :item, as: :entries, class: Oasis::MrssEntry

        attr_accessor :feed_url

        REGEX_MATCH = %r{http://purl.org/rss/1.0/modules/content/|http://search.yahoo.com/mrss/}

        def self.able_to_parse?(first_2k_xml)
          first_2k_xml =~ REGEX_MATCH
        end
      end
    end
  end
end
