# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe ItemRelation do
    let(:supplejack_set) { Supplejack::UserSet.new(id: '1234567890', records: [{ record_id: 1, position: 1 }]) }
    let(:relation) { described_class.new(supplejack_set) }

    describe '#initialize' do
      it 'assigns the user_set object as @user_set' do
        expect(relation.user_set).to eq supplejack_set
      end

      it 'initializes an array of Supplejack::Items' do
        expect(relation.items).to be_a Array
      end

      it 'returns an empty array of items when the user_set attributes records are nil' do
        allow(supplejack_set).to receive(:attributes).and_return({})

        expect(relation.items).to be_empty
      end

      it 'adds the user_set_id to the Supplejack::Item object' do
        expect(relation.items.first.user_set_id).to eq '1234567890'
      end

      it 'adds the api_key in the user_set to the Supplejack::Item' do
        supplejack_set.api_key = 'abc123'

        expect(relation.items.first.api_key).to eq 'abc123'
      end
    end

    describe '#all' do
      it 'returns the array of @items' do
        expect(supplejack_set.items.all).to be_a Array
      end
    end

    describe '#find' do
      it 'returns finds the item by record_id' do
        item = relation.find(1)

        expect(item).to be_a Supplejack::Item
        expect(item.record_id).to eq 1
      end

      it 'finds the item by a string record_id' do
        item = relation.find('1')

        expect(item).to be_a Supplejack::Item
        expect(item.record_id).to eq 1
      end
    end

    describe '#build' do
      it 'initializes a new item object with the user_set_id' do
        expect(relation.build.user_set_id).to eq '1234567890'
      end

      it 'accepts a hash of attributes' do
        item = relation.build(record_id: 2, position: 9)

        expect(item.record_id).to eq 2
        expect(item.position).to eq 9
      end

      it 'adds the user_set api_key' do
        allow(relation).to receive(:user_set) { instance_double(Supplejack::UserSet, api_key: '1234').as_null_object }
        item = relation.build

        expect(item.api_key).to eq '1234'
      end
    end

    describe '#create' do
      let(:item) { instance_double(Supplejack::UserSet).as_null_object }

      it 'builds and saves the item' do
        allow(relation).to receive(:build).and_return(item)
        expect(item).to receive(:save)

        relation.create
      end

      it 'passes the parameters along to the build method' do
        allow(relation).to receive(:build).with({record_id: 8, position: 3}).and_return(item)

        relation.create({record_id: 8, position: 3})
      end
    end

    context 'when items behaves as array' do
      it 'executes array methods on the @items array' do
        relation = described_class.new(supplejack_set)
        items = relation.instance_variable_get('@items')

        expect(items).to receive(:size)

        relation.size
      end

      it 'iterates through the items relation' do
        relation = described_class.new(supplejack_set)

        expect(relation).to all(be_a Supplejack::Item)
        expect(relation.size).to eq 1
      end
    end
  end
end
