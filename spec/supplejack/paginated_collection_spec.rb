# frozen_string_literal: true

require 'spec_helper'

describe 'PaginatedCollection' do
  subject { Supplejack::PaginatedCollection.new [], 1, 10, 20 }

  it { expect(subject).to be_an Array }

  context 'behaves like a WillPaginate::Collection' do
    it { expect(subject.total_entries).to eq 20 }
    it { expect(subject.total_pages).to eq 2 }
    it { expect(subject.current_page).to eq 1 }
    it { expect(subject.per_page).to eq 10 }
    it { expect(subject.previous_page).to be nil }
    it { expect(subject.next_page).to eq 2 }
    it { expect(subject.out_of_bounds?).not_to be true }
    it { expect(subject.offset).to eq 0 }

    it 'should allow setting total_count' do
      subject.total_count = 1

      expect(subject.total_count).to eq 1
    end

    it 'should allow setting total_entries' do
      subject.total_entries = 1

      expect(subject.total_entries).to eq 1
    end
  end

  context 'behaves like Kaminari' do
    it { expect(subject.total_count).to eq 20 }
    it { expect(subject.num_pages).to eq 2 }
    it { expect(subject.limit_value).to eq 10 }
    it { expect(subject.first_page?).to be true }
    it { expect(subject.last_page?).not_to be true }
  end
end
