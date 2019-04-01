# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
require 'rails_helper'

describe InstagramProfile do
  it_behaves_like 'a model with an aliased index name'
end
