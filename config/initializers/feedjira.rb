# frozen_string_literal: true

require 'feedjira/parser/oasis/mrss'

Feedjira.configure do |config|
  config.parsers.unshift(Feedjira::Parser::Oasis::Mrss)
end