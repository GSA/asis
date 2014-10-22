module Feedjira
  module Parser
    module Oasis
      class MrssEntry
        include SAXMachine
        include FeedEntryUtilities

        element :title
        element :link, :as => :url
        element :pubDate, :as => :published
        element :guid, :as => :entry_id
        element 'media:thumbnail', :value => :url, :as => :thumbnail_url
        element 'media:description', :as => :summary

        def title
          @title.strip.squish
        end

        def summary
          @summary.strip.squish
        end
      end

      class Mrss
        include SAXMachine
        include FeedUtilities

        element :title
        element :link
        element :description

        elements :item, :as => :entries, :class => Oasis::MrssEntry

        attr_accessor :feed_url

        def self.able_to_parse?(first_2k_xml)
          first_2k_xml.include? 'http://search.yahoo.com/mrss/'
        end
      end
    end
  end
end