# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe UserStoryRelation do
    let(:user) { Supplejack::User.new(id: 'user_id_1', authentication_token: '123abc') }
    let(:relation) { described_class.new(user) }

    before do
      allow(relation).to receive(:get).and_return(
        [
          {
            'id' => '1',
            'name' => 'dogs',
            'description' => 'desc',
            'privacy' => 'public',
            'featured' => false,
            'approved' => true,
            'number_of_items' => 1
          },
          {
            'id' => '2',
            'name' => 'cats',
            'description' => 'desc',
            'privacy' => 'public',
            'featured' => false,
            'approved' => true,
            'number_of_items' => 1
          }
        ]
      )
    end

    describe '#initialize' do
      it 'initializes with a UserSet object' do
        expect(described_class.new(user).user).to eq(user)
      end
    end

    describe '#find' do
      it 'calls get method with story path and user_key' do
        expect(relation).to receive(:get).with('/stories/th1s1sast0ry1d', user_key: '123abc')

        relation.find('th1s1sast0ry1d')
      end
    end

    describe '#fetch' do
      context 'when use_own_api_key is false' do
        it 'fetches the users stories with the App api_key' do
          expect(relation).to receive(:get).with('/users/user_id_1/stories', { user_key: '123abc' })

          relation.fetch
        end
      end

      context 'when use_own_api_key is true' do
        let(:user) { Supplejack::User.new(id: 'user_id_1', api_key: '123abc', use_own_api_key: true) }

        it 'fetches the users stories with their api_key' do
          expect(relation).to receive(:get).with('/stories', { user_key: '123abc' })

          relation.fetch
        end
      end

      it 'returns a array of Story objects' do
        expect(relation.fetch).to be_a Array

        expect(relation).to all(be_a Supplejack::Story)
      end

      it 'memoizes the result' do
        expect(relation).to receive(:fetch_api_stories).once.and_return([])

        relation.fetch
        relation.fetch
      end

      it 'lets you force a refetch' do
        expect(relation).to receive(:fetch_api_stories).twice.and_return([])

        relation.fetch
        relation.fetch(force: true)
      end
    end

    describe '#build' do
      it "initializes a new Story with the user's api_key" do
        story = relation.build

        expect(story).to be_a Supplejack::Story
        expect(story.api_key).to eq('123abc')
      end

      it 'initializes the Story with the provided attributes' do
        story = relation.build(name: 'Dogs', description: 'Hi')

        expect(story.name).to eq('Dogs')
        expect(story.description).to eq('Hi')
      end
    end

    describe '#create' do
      it 'initializes the Story and saves it' do
        story = relation.build(name: 'Dogs')
        allow(relation).to receive(:build).with({ name: 'Dogs' }).and_return(story)
        allow(story).to receive(:save).and_return(true)

        expect(relation.create({ name: 'Dogs' })).to be_a Supplejack::Story
      end

      it 'adds the new Story to the relation' do
        expect(relation.count).to eq(2)
        relation.create(name: 'Dogs')
        expect(relation.count).to eq(3)
      end
    end

    describe '#order' do
      before do
        allow(relation).to receive(:get).and_return(
          [{ 'name' => 'dogs' },
           { 'name' => 'zavourites' },
           { 'name' => 'Favourites' }]
        )
      end

      it 'orders the stories based on the supplied field' do
        ordered_relations = relation.order(:name)

        expect(ordered_relations.map(&:name)).to eq %w[dogs Favourites zavourites]
      end
    end

    describe '#all' do
      it 'is an alias to #fetch' do
        expect(relation.all).to eq(relation.fetch)
      end
    end

    context 'when stories array behaviour' do
      it 'executes array methods on the @stories array' do
        allow(relation).to receive(:all).and_return([])

        expect(relation.size).to eq(0)
      end
    end
  end
end
