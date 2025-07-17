# frozen_string_literal: true

require 'rails_helper'

# This is a dummy class used to test the AliasedIndex concern in isolation.
# It needs to behave enough like a model for the concern's methods to work.
class AliasedIndexTestModel
  extend ActiveModel::Naming
  include ActiveModel::Model

  # Include the modules we are actually testing.
  include Elasticsearch::Persistence::Model
  include AliasedIndex
end

describe AliasedIndex, type: :model do
  # Use the dummy model as the subject of the spec.
  subject(:model) { AliasedIndexTestModel }

  # Create instance doubles for the Elasticsearch client and its indices namespace.
  let(:client) { instance_double(Elasticsearch::Transport::Client) }
  let(:indices) { instance_double(Elasticsearch::API::Indices::IndicesClient) }

  # The alias name is dynamically generated, so we call the method to get it.
  let(:alias_name) { model.alias_name }

  before do
    allow(Elasticsearch::Persistence).to receive(:client).and_return(client)
    allow(client).to receive(:indices).and_return(indices)

    # Stub `puts` on the model to prevent console output during test runs.
    allow(model).to receive(:puts)
  end

  describe '.delete_index_and_alias!' do
    context 'when the alias points to existing indices' do
      # These are example index names that the alias might point to.
      let(:index_names) { ["#{model.base_name}-1", "#{model.base_name}-2"] }

      before do
        # Mock the response for `get_alias` to simulate that the alias exists
        # and points to our two test indices. The real API returns a hash
        # where the keys are the index names.
        allow(indices).to receive(:get_alias).with(name: alias_name).and_return(index_names.index_with { |_| {} })
        # We also need to allow the `delete` call that we expect to happen.
        allow(indices).to receive(:delete).with(index: index_names.join(','))
      end

      it 'deletes all indices associated with the alias' do
        expect(indices).to receive(:delete).with(index: index_names.join(','))
        model.delete_index_and_alias!
      end
    end

    context "when the alias does not exist" do
      before do
        # Mock the `get_alias` call to simulate a scenario where the alias
        # is not found, which raises a `NotFound` error.
        allow(indices).to receive(:get_alias)
          .with(name: alias_name)
          .and_raise(Elasticsearch::Transport::Transport::Errors::NotFound.new('alias not found'))
      end

      it 'rescues the NotFound error and does not bubble it up' do
        expect { model.delete_index_and_alias! }.not_to raise_error
      end

      it 'does not attempt to delete any indices' do
        # If the alias doesn't exist, no delete operation should be attempted.
        expect(indices).not_to receive(:delete)
        model.delete_index_and_alias!
      end
    end
  end
end
