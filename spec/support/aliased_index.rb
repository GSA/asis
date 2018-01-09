shared_examples "a model with an aliased index name" do
  describe "alias_exists?" do
    context 'when alias exists' do
      it 'should return true' do
        expect(described_class.alias_exists?).to be_truthy
      end
    end

    context 'when alias does not exist' do
      before do
        expect(Elasticsearch::Persistence.client.indices).to receive(:get_alias).with(name: described_class.alias_name).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)
      end

      it 'should return false' do
        expect(described_class.alias_exists?).to be_falsey
      end
    end
  end
end
