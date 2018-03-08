# frozen_string_literal: true

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

        def url
          ensure_scheme_present(@url)
        end

        def thumbnail_url
          ensure_scheme_present(@thumbnail_url)
        end

        private

        def sanitize(unsafe_html)
          doc = Loofah.fragment(unsafe_html)
          doc.text.strip.squish
        end

        def ensure_scheme_present(link)
          link =~ %r{^https?://}i ? link : "http://#{link}"
        end
      end
    end
  end
end
