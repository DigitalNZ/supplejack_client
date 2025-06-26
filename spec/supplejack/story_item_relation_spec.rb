# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe ItemRelation do
    let(:supplejack_story) do
      Supplejack::Story.new(
        id: '1234567890',
        user: { api_key: 'foobar' },
        name: 'test',
        contents: [
          { id: 1, type: 'embed', sub_type: 'supplejack_user', position: 1 },
          { id: 2, type: 'embed', sub_type: 'supplejack_user', position: 2 }
        ]
      )
    end
    let(:relation) { Supplejack::StoryItemRelation.new(supplejack_story) }

    describe '#initialize' do
      it 'assigns the story object as @story' do
        expect(relation.story).to eq(supplejack_story)
      end

      it 'initializes an array of Supplejack::Items' do
        expect(relation.all).to be_an Array
      end

      it 'returns an empty array of items when the user_set attributes records are nil' do
        allow(supplejack_story).to receive(:attributes).and_return(nil)

        expect(relation.all).to be_empty
      end

      it 'adds the story_id to the Supplejack::StoryItem object' do
        expect(relation.all.first.story_id).to eq('1234567890')
      end

      it 'adds the api_key in the Story to the Supplejack::StoryItem' do
        expect(relation.all.first.api_key).to eq('foobar')
      end
    end

    describe '#all' do
      it 'returns the array of @items' do
        expect(supplejack_story.items.all).to be_an Array
      end
    end

    describe '#find' do
      it 'returns finds the item by record_id' do
        item = relation.find(1)
        expect(item).to be_a Supplejack::StoryItem
        expect(item.id).to eq(1)
      end

      it 'finds the item by a string record_id' do
        item = relation.find('1')

        expect(item).to be_a Supplejack::StoryItem
        expect(item.id).to eq(1)
      end
    end

    describe '#build' do
      it 'initializes a new item object with the user_set_id' do
        item = relation.build

        expect(item.story_id).to eq('1234567890')
      end

      it 'accepts a hash of attributes' do
        item = relation.build(type: 'embed', sub_type: 'supplejack_user')

        expect(item.type).to eq('embed')
        expect(item.sub_type).to eq('supplejack_user')
      end

      it 'adds the Story api_key' do
        item = relation.build

        expect(item.api_key).to eq('foobar')
      end
    end

    describe '#create' do
      let(:item) { instance_double(Supplejack::StoryItem).as_null_object }

      it 'builds and saves the item' do
        allow(relation).to receive(:build).and_return(item)
        expect(item).to receive(:save)

        relation.create
      end

      it 'passes the parameters along to the build method' do
        allow(relation).to receive(:build).with({ type: 'embed' }).and_return(item)

        expect(relation.create({ type: 'embed' })).not_to be_nil
      end
    end

    context 'when items are arrays' do
      it 'executes array methods on the @items array' do
        expect(relation.any? { |x| x.id == 1 }).to be(true)
      end

      it 'iterates through the items relation' do
        expect(relation).to all(be_a Supplejack::StoryItem)
        expect(relation.size).to eq(2)
      end
    end
  end
end
