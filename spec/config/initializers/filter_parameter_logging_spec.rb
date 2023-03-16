# frozen_string_literal: true

require 'rails_helper'

describe 'ActiveSupport::ParameterFilter' do
  let(:config) { Oasis::Application.config }
  let(:parameter_filter) { ActiveSupport::ParameterFilter.new(config.filter_parameters) }

  it 'filters query from logs' do
    expect(config.filter_parameters).to match(array_including(:query))
  end
end
