# frozen_string_literal: true

shared_examples 'a model with an aliased index name' do
  describe 'alias_exists?' do
    context 'when alias exists' do
      it 'returns true' do
        expect(described_class.alias_exists?).to be_truthy
      end
    end

    context 'when alias does not exist' do
      before do
        allow(Elasticsearch::Persistence.client.indices).to receive(:get_alias).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)
      end

      it 'returns false' do
        expect(described_class.alias_exists?).to be_falsey
      end
    end
  end
end
