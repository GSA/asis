module Feedjira
  module Parser
    module Oasis
      class MrssEntry
        include SAXMachine
        include FeedEntryUtilities

        element :guid, as: :entry_id
        element :'dc:identifier', as: :entry_id

        element :title

        element :link, as: :url

        element :pubDate, as: :published
        element :pubdate, as: :published
        element :'dc:date', as: :published
        element :'dc:Date', as: :published
        element :'dcterms:created', as: :published
        element :issued, as: :published

        element 'media:thumbnail', value: :url, as: :thumbnail_url

        element :description, as: :summary
        element 'media:description', as: :summary
        element 'content:encoded', as: :summary

        def title
          sanitize @title
        end

        def summary
          sanitize @summary
        end

        private

        def sanitize(unsafe_html)
          doc = Loofah.fragment(unsafe_html)
          doc.text.strip.squish
        end
      end
    end
  end
end