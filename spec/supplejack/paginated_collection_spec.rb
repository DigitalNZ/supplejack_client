# frozen_string_literal: true

require 'spec_helper'

describe 'PaginatedCollection' do
  subject(:collection) { Supplejack::PaginatedCollection.new [], 1, 10, 20 }

  it { expect(collection).to be_an Array }

  context 'when behaves like a WillPaginate::Collection' do
    it { expect(collection.total_entries).to eq 20 }
    it { expect(collection.total_pages).to eq 2 }
    it { expect(collection.current_page).to eq 1 }
    it { expect(collection.per_page).to eq 10 }
    it { expect(collection.previous_page).to be_nil }
    it { expect(collection.next_page).to eq 2 }
    it { expect(collection.out_of_bounds?).not_to be true }
    it { expect(collection.offset).to eq 0 }

    it 'allows setting total_count' do
      collection.total_count = 1

      expect(collection.total_count).to eq 1
    end

    it 'allows setting total_entries' do
      collection.total_entries = 1

      expect(collection.total_entries).to eq 1
    end
  end

  context 'when behaves like Kaminari' do
    it { expect(collection.total_count).to eq 20 }
    it { expect(collection.num_pages).to eq 2 }
    it { expect(collection.limit_value).to eq 10 }
    it { expect(collection.first_page?).to be true }
    it { expect(collection.last_page?).not_to be true }
  end
end
