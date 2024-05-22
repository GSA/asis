# frozen_string_literal: true

require 'rails_helper'

describe 'ActiveSupport::ParameterFilter' do
  let(:config) { Oasis::Application.config }
  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(config.filter_parameters) }

  it 'filters query from logs' do
    regex = config.filter_parameters.first
    expect(regex).to be_a(Regexp)
    expect(regex.source).to include('query')
  end
end
