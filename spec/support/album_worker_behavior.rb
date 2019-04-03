shared_examples_for 'an album worker' do
  subject(:perform) { described_class.new.perform(id) }
  let(:iterator) { instance_double(AlbumDetectionPhotoIterator) }

  describe '.perform' do
    it 'runs the AlbumDetectionPhotoIterator on photos for the given source' do
      expect(AlbumDetectionPhotoIterator).to receive(:new).
        with(photo_class,
             PhotoFilter.new(id_type, id.downcase).query_body).
        and_return(iterator)
      expect(iterator).to receive(:run)
      perform
    end
  end
end
