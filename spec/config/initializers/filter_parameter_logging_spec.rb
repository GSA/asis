# frozen_string_literal: true

require 'rails_helper'

describe 'ActiveSupport::ParameterFilter' do
  let(:config) { Oasis::Application.config }
  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(config.filter_parameters) }

  it 'filters query from logs' do
    query_string = 'query'
    regexes = config.filter_parameters.map { |param| param.is_a?(Regexp) ? param : Regexp.new(Regexp.escape(param.to_s), Regexp::IGNORECASE) }
    pattern_found = regexes.any? { |regex| query_string.match?(regex) }
    expect(pattern_found).to be true
  end
end
