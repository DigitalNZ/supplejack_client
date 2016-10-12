# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe ItemRelation do
    let(:supplejack_story) { Supplejack::Story.new(id: '1234567890', user: {api_key: 'foobar'}, name: 'test', contents: [{id: 1, type: 'embed', sub_type: 'dnz'}]) }
    let(:relation) { Supplejack::StoryItemRelation.new(supplejack_story) }

    describe '#initialize' do
      it 'assigns the story object as @story' do
        expect(Supplejack::StoryItemRelation.new(supplejack_story).story).to eq(supplejack_story)
      end

      it 'initializes an array of Supplejack::Items' do
        expect(Supplejack::StoryItemRelation.new(supplejack_story).all).to be_an Array
      end

      it 'returns an empty array of items when the user_set attributes records are nil' do
        expect(supplejack_story).to receive(:attributes).and_return(nil)

        expect(Supplejack::StoryItemRelation.new(supplejack_story).all).to be_empty
      end

      it 'adds the story_id to the Supplejack::StoryItem object' do
        expect(Supplejack::StoryItemRelation.new(supplejack_story).all.first.story_id).to eq('1234567890')
      end

      it 'adds the api_key in the Story to the Supplejack::StoryItem' do
        expect(Supplejack::StoryItemRelation.new(supplejack_story).all.first.api_key).to eq('foobar')
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
        item = relation.build(type: 'embed', sub_type: 'dnz')

        expect(item.type).to eq('embed')
        expect(item.sub_type).to eq('dnz')
      end

      it 'adds the Story api_key' do
        item = relation.build

        expect(item.api_key).to eq('foobar')
      end
    end

    describe '#create' do
      let(:item) { double(:item).as_null_object }

      it 'builds and saves the item' do
        expect(relation).to receive(:build) { item }
        expect(item).to receive(:save)

        relation.create
      end

      it 'passes the parameters along to the build method' do
        expect(relation).to receive(:build).with(type: 'embed') { item }

        relation.create(type: 'embed')
      end
    end

    context 'items array behaviour' do
      it 'executes array methods on the @items array' do
        relation = Supplejack::StoryItemRelation.new(supplejack_story)

        expect(relation.any?{|x| x.id == 1}).to eq(true)
      end

      it 'should be able to iterate through the items relation' do
        relation = Supplejack::StoryItemRelation.new(supplejack_story)

        relation.each do |item|
          expect(item).to be_a Supplejack::StoryItem
        end

        expect(relation.size).to eq(1)
      end
    end
  end
end

