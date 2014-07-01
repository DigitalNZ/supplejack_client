# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe UserSetRelation do
    let(:user) { Supplejack::User.new({authentication_token: '123abc'}) }
    let(:relation) { Supplejack::UserSetRelation.new(user) }

    before :each do
      relation.stub(:get) { {'sets' => [{'id' => '1', 'name' => 'dogs', 'count' => 1, 'priority' => 2}, {'id' => '2', 'name' => 'Favourites', 'count' => 1, 'priority' => 1}]} }
    end
    
    describe '#initialize' do
      it 'initializes with a UserSet object' do
        @user = user
        Supplejack::UserSetRelation.new(@user).user.should eq @user
      end
    end

    describe '#fetch_sets' do
      it 'fetches the user sets with the App api_key' do
        relation.should_receive(:get).with('/users/123abc/sets', {})
        relation.fetch_sets
      end

      it 'returns a array of UserSet objects' do
        relation.fetch_sets.should be_a Array
        relation.fetch_sets.each do |set|
          set.should be_a Supplejack::UserSet
        end
      end
      
      it 'should order the user sets by priority' do
        relation.fetch_sets.first.name.should eq 'Favourites'
        relation.fetch_sets.last.name.should eq 'dogs'
      end
    end

    describe 'sets_response' do
      context 'caching disabled' do
        before :each do
          Supplejack.stub(:enable_caching) { false }
        end

        it 'fetches the user sets with the App api_key' do
          relation.should_receive(:get).with('/users/123abc/sets', {})
          relation.sets_response
        end

        context 'user with use_own_api_key set to true' do
          it 'fetches the user sets with it\'s own API Key' do
            user.stub(:use_own_api_key?) { true }
            relation.should_receive(:get).with('/sets', {api_key: '123abc'})
            relation.sets_response
          end
        end
      end
    end

    describe '#sets' do
      it 'memoizes the sets array' do
        relation.should_receive(:fetch_sets).once { [] }
        relation.sets
        relation.sets
      end
    end

    describe '#find' do
      it 'finds a user and sets the correct api_key' do
        Supplejack::UserSet.should_receive(:find).with('555', '123abc')
        relation.find('555')
      end
    end

    describe '#build' do
      it 'initializes a new UserSet with the user\'s api_key' do
        user_set = relation.build
        user_set.should be_a UserSet
        user_set.api_key.should eq '123abc'
      end

      it 'initializes the UserSet with the provided attributes' do
        user_set = relation.build({name: 'Dogs', description: 'Hi'})
        user_set.name.should eq 'Dogs'
        user_set.description.should eq 'Hi'
      end
    end

    describe '#create' do
      it 'initializes the UserSet and saves it' do
        user_set = relation.build({name: 'Dogs'})
        relation.should_receive(:build).with(name: 'Dogs') { user_set }
        user_set.should_receive(:save) { true }
        relation.create({name: 'Dogs'}).should be_a Supplejack::UserSet
      end
    end

    describe '#order' do
      before :each do
        relation.stub(:get) { {'sets' => [{'name' => 'dogs', 'priority' => 2, 'count' => 3}, { 'name' => 'zavourites', 'priority' => 1, 'count' => 2},{ 'name' => 'Favourites', 'priority' => 2, 'count' => 1}]} }      
      end
      it 'orders the sets based on the name' do
        relation.order(:name)[0].name.should eq 'zavourites'
        relation.order(:name)[1].name.should eq 'dogs'
        relation.order(:name)[2].name.should eq 'Favourites'
      end
      it 'orders the sets based on the count' do
        relation.order(:count)[0].name.should eq 'zavourites'
        relation.order(:count)[1].name.should eq 'Favourites'
        relation.order(:count)[2].name.should eq 'dogs' 
      end

      it 'orders the sets based on the updated_at ignoring the priority' do
        relation.stub(:get) { {'sets' => [{'name' => '1', 'updated_at' => Time.now.to_s, 'priority' => 2}, {'name' => '3', 'updated_at' => (Time.now-4.hours).to_s, 'priority' => 1},{'name' => '2', 'updated_at' => (Time.now-1.hours).to_s, 'priority' => 2}]} }
        relation.order(:updated_at)[0].name.should eq '1'
        relation.order(:updated_at)[1].name.should eq '2'
        relation.order(:updated_at)[2].name.should eq '3'
      end
    end

    describe '#all' do
      it 'returns the actual array with the sets' do
        relation.all.should be_a Array
      end
    end

    context 'user sets array behaviour' do
      it 'executes array methods on the @sets array' do
        sets = relation.stub(:sets) { [] }
        relation.size.should eq 0
      end

      it 'should be able to iterate through the user sets relation' do
        relation.stub(:sets) { [Supplejack::UserSet.new] }
        relation.each do |set|
          set.should be_a Supplejack::UserSet
        end
        relation.size.should eq 1
      end
    end

  end
end
