# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe Facet do
    it 'initializes the facet with a name' do
      facet = described_class.new('description', {})

      expect(facet.name).to eq('description')
    end

    it 'initializes the facet with values' do
      facet = described_class.new('location', 'Wellington' => 100, 'Auckland' => 10)

      expect(facet.values).to eq('Wellington' => 100, 'Auckland' => 10)
    end

    context 'when sorting' do
      let(:facet) { described_class.new('location', 'Wellington' => 100, 'Auckland' => 10, 'Dunedin' => 5, 'Queenstown' => 30) }

      it 'sorts by alphabetical order set in config' do
        allow(Supplejack).to receive(:facets_sort).and_return(:index)

        expect(facet.values.keys).to eq %w[Auckland Dunedin Queenstown Wellington]
        expect(facet.values.values).to eq [10, 5, 30, 100]
      end

      it 'sorts by count set in the config' do
        allow(Supplejack).to receive(:facets_sort).and_return(:count)

        expect(facet.values.keys).to eq %w[Wellington Queenstown Auckland Dunedin]
        expect(facet.values.values).to eq [100, 30, 10, 5]
      end

      it 'overrides the global facets sort' do
        allow(Supplejack).to receive(:facets_sort).and_return(:count)

        expect(facet.values(:index).keys).to eq %w[Auckland Dunedin Queenstown Wellington]
      end
    end
  end
end
