require 'rails_helper'

describe MrssPhotosAlbumWorker do
  let(:photo_class) { MrssPhoto }
  let(:id_type) { 'mrss_url' }
  let(:id) { 'http://foo.gov/photos.xml' }

  it_behaves_like 'an album worker'
end
