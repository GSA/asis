# frozen_string_literal: true

require 'rails_helper'

describe 'ActiveSupport::ParameterFilter' do
  let(:config) { Oasis::Application.config }
  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(config.filter_parameters) }

  it 'filters query from logs' do
    pattern_found = config.filter_parameters.any? { |regex| regex =~ /query/i }
    expect(pattern_found).to be true
  end
end
