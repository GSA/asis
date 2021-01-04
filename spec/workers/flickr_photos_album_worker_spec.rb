# frozen_string_literal: true

require 'rails_helper'

describe FlickrPhotosAlbumWorker do
  let(:photo_class) { FlickrPhoto }
  let(:id_type) { 'owner' }
  let(:id) { '61913304@N07' }

  it_behaves_like 'an album worker'
end
