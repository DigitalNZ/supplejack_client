# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe ItemRelation do
    let(:supplejack_set) { Supplejack::UserSet.new(id: '1234567890', records: [{record_id: 1, position: 1}]) }
    let(:relation) { Supplejack::ItemRelation.new(supplejack_set) }
  
    describe '#initialize' do
      it 'assigns the user_set object as @user_set' do
        Supplejack::ItemRelation.new(supplejack_set).user_set.should eq supplejack_set
      end

      it 'initializes an array of Supplejack::Items' do
        Supplejack::ItemRelation.new(supplejack_set).items.should be_a Array
      end

      it 'returns an empty array of items when the user_set attributes records are nil' do
        supplejack_set.stub(:attributes) { {} }
        Supplejack::ItemRelation.new(supplejack_set).items.should be_empty
      end

      it 'adds the user_set_id to the Supplejack::Item object' do
        Supplejack::ItemRelation.new(supplejack_set).items.first.user_set_id.should eq '1234567890'
      end

      it 'adds the api_key in the user_set to the Supplejack::Item' do
        supplejack_set.api_key = 'abc123'
        Supplejack::ItemRelation.new(supplejack_set).items.first.api_key.should eq 'abc123'
      end
    end

    describe '#all' do
      it 'returns the array of @items' do
        supplejack_set.items.all.should be_a Array
      end
    end

    describe '#find' do
      it 'returns finds the item by record_id' do
        item = relation.find(1)
        item.should be_a Supplejack::Item
        item.record_id.should eq 1
      end

      it 'finds the item by a string record_id' do
        item = relation.find('1')
        item.should be_a Supplejack::Item
        item.record_id.should eq 1
      end
    end

    describe '#build' do
      it 'initializes a new item object with the user_set_id' do
        item = relation.build
        item.user_set_id.should eq '1234567890'
      end

      it 'accepts a hash of attributes' do
        item = relation.build(record_id: 2, position: 9)
        item.record_id.should eq 2
        item.position.should eq 9
      end

      it 'adds the user_set api_key' do
        relation.stub(:user_set) { double(:user_set, api_key: '1234').as_null_object }
        item = relation.build
        item.api_key.should eq '1234'
      end
    end

    describe '#create' do
      let(:item) { double(:item).as_null_object }

      it 'builds and saves the item' do
        relation.should_receive(:build) { item }
        item.should_receive(:save)
        relation.create
      end

      it 'passes the parameters along to the build method' do
        relation.should_receive(:build).with(record_id: 8, position: 3) { item }
        relation.create(record_id: 8, position: 3)
      end
    end

    context 'items array behaviour' do
      it 'executes array methods on the @items array' do
        relation = Supplejack::ItemRelation.new(supplejack_set)
        items = relation.instance_variable_get('@items')
        items.should_receive(:size)
        relation.size
      end

      it 'should be able to iterate through the items relation' do
        relation = Supplejack::ItemRelation.new(supplejack_set)
        relation.each do |item|
          item.should be_a Supplejack::Item
        end
        relation.size.should eq 1
      end
    end
  end
end

