# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe UserSetRelation do
    let(:user) { Supplejack::User.new(authentication_token: '123abc') }
    let(:relation) { Supplejack::UserSetRelation.new(user) }

    before :each do
      allow(relation).to receive(:get) { { 'sets' => [{ 'id' => '1', 'name' => 'dogs', 'count' => 1, 'priority' => 2 }, { 'id' => '2', 'name' => 'Favourites', 'count' => 1, 'priority' => 1 }] } }
    end

    describe '#initialize' do
      it 'initializes with a UserSet object' do
        @user = user
        expect(Supplejack::UserSetRelation.new(@user).user).to eq @user
      end
    end

    describe '#fetch_sets' do
      it 'fetches the user sets with the App api_key' do
        expect(relation).to receive(:get).with('/users/123abc/sets', {})

        relation.fetch_sets
      end

      it 'returns a array of UserSet objects' do
        expect(relation.fetch_sets).to be_a Array

        relation.fetch_sets.each do |set|
          expect(set).to be_a Supplejack::UserSet
        end
      end

      it 'should order the user sets by priority' do
        expect(relation.fetch_sets.first.name).to eq 'Favourites'

        expect(relation.fetch_sets.last.name).to eq 'dogs'
      end
    end

    describe 'sets_response' do
      context 'caching disabled' do
        before { allow(Supplejack).to receive(:enable_caching) { false } }

        it 'fetches the user sets with the App api_key' do
          expect(relation).to receive(:get).with('/users/123abc/sets', {})

          relation.sets_response
        end

        context 'user with use_own_api_key set to true' do
          it 'fetches the user sets with it\'s own API Key' do
            allow(user).to receive(:use_own_api_key?) { true }

            expect(relation).to receive(:get).with('/sets', api_key: '123abc')

            relation.sets_response
          end
        end
      end
    end

    describe '#sets' do
      it 'memoizes the sets array' do
        expect(relation).to receive(:fetch_sets).once.and_return([])

        relation.sets
        relation.sets
      end
    end

    describe '#find' do
      it 'finds a user and sets the correct api_key' do
        expect(Supplejack::UserSet).to receive(:find).with('555', '123abc')

        relation.find('555')
      end
    end

    describe '#build' do
      it 'initializes a new UserSet with the user\'s api_key' do
        user_set = relation.build

        expect(user_set).to be_a UserSet
        expect(user_set.api_key).to eq '123abc'
      end

      it 'initializes the UserSet with the provided attributes' do
        user_set = relation.build(name: 'Dogs', description: 'Hi')

        expect(user_set.name).to eq 'Dogs'
        expect(user_set.description).to eq 'Hi'
      end
    end

    describe '#create' do
      it 'initializes the UserSet and saves it' do
        user_set = relation.build(name: 'Dogs')

        expect(relation).to receive(:build).with(name: 'Dogs') { user_set }
        expect(user_set).to receive(:save) { true }
        expect(relation.create(name: 'Dogs')).to be_a Supplejack::UserSet
      end
    end

    describe '#order' do
      before :each do
        allow(relation).to receive(:get) { { 'sets' => [{ 'name' => 'dogs', 'priority' => 2, 'count' => 3 }, { 'name' => 'zavourites', 'priority' => 1, 'count' => 2 }, { 'name' => 'Favourites', 'priority' => 2, 'count' => 1 }] } }
      end

      it 'orders the sets based on the name' do
        expect(relation.order(:name)[0].name).to eq 'zavourites'
        expect(relation.order(:name)[1].name).to eq 'dogs'
        expect(relation.order(:name)[2].name).to eq 'Favourites'
      end
      it 'orders the sets based on the count' do
        expect(relation.order(:count)[0].name).to eq 'zavourites'
        expect(relation.order(:count)[1].name).to eq 'Favourites'
        expect(relation.order(:count)[2].name).to eq 'dogs'
      end

      it 'orders the sets based on the updated_at ignoring the priority' do
        allow(relation).to receive(:get) do
          { 'sets' => [
            { 'name' => '1', 'updated_at' => Time.now.to_s, 'priority' => 2 },
            { 'name' => '3', 'updated_at' => (Time.now - 4.hours).to_s, 'priority' => 1 },
            { 'name' => '2', 'updated_at' => (Time.now - 1.hour).to_s, 'priority' => 2 }
          ] }
        end

        expect(relation.order(:updated_at)[0].name).to eq '1'
        expect(relation.order(:updated_at)[1].name).to eq '2'
        expect(relation.order(:updated_at)[2].name).to eq '3'
      end
    end

    describe '#all' do
      it 'returns the actual array with the sets' do
        expect(relation.all).to be_a Array
      end
    end

    context 'user sets array behaviour' do
      it 'executes array methods on the @sets array' do
        allow(relation).to receive(:sets) { [] }

        expect(relation.size).to eq 0
      end

      it 'should be able to iterate through the user sets relation' do
        allow(relation).to receive(:sets) { [Supplejack::UserSet.new] }

        relation.each do |set|
          expect(set).to be_a Supplejack::UserSet
        end

        expect(relation.size).to eq 1
      end
    end
  end
end
