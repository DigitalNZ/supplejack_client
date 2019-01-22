# frozen_string_literal: true

require 'spec_helper'

describe 'PaginatedCollection' do
  subject { Supplejack::PaginatedCollection.new [], 1, 10, 20 }

  it { subject.should be_an(Array) }

  context 'behaves like a WillPaginate::Collection' do
    it { subject.total_entries.should eql(20) }
    it { subject.total_pages.should eql(2) }
    it { subject.current_page.should eql(1) }
    it { subject.per_page.should eql(10) }
    it { subject.previous_page.should be_nil }
    it { subject.next_page.should eql(2) }
    it { subject.out_of_bounds?.should_not be_truthy }
    it { subject.offset.should eql(0) }

    it 'should allow setting total_count' do
      subject.total_count = 1
      subject.total_count.should eql(1)
    end

    it 'should allow setting total_entries' do
      subject.total_entries = 1
      subject.total_entries.should eql(1)
    end
  end

  context 'behaves like Kaminari' do
    it { subject.total_count.should eql(20) }
    it { subject.num_pages.should eql(2) }
    it { subject.limit_value.should eql(10) }
    it { subject.first_page?.should be_truthy }
    it { subject.last_page?.should_not be_truthy }
  end
end
