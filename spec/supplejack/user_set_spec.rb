# frozen_string_literal: true

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

module Supplejack
  describe UserSet do
    let(:supplejack_set) { Supplejack::UserSet.new(records: [{ record_id: 1, position: 2, title: 'Dogs' }]) }

    before :each do
      allow(Supplejack).to receive(:enable_caching) { false }
      allow(Supplejack::UserSet).to receive(:get) { { 'set' => { id: '123abc', name: 'Dogs', count: 0 } } }
    end

    describe '#initialize' do
      %i[id name description privacy url priority count tag_list featured approved].each do |attribute|
        it "initializes the #{attribute}" do
          expect(Supplejack::UserSet.new(attribute => 'value').send(attribute)).to eq 'value'
        end
      end

      it 'converts the updated_at into a time object' do
        expect(Supplejack::UserSet.new(updated_at: '2012-08-17T10:01:00+12:00').updated_at).to be_a Time
      end

      it 'symbolizes the attributes hash' do
        expect(Supplejack::UserSet.new('name' => 'Dog').name).to eq 'Dog'
      end

      it 'initializes a user object' do
        user_set = Supplejack::UserSet.new(user: { name: 'Juanito' })

        expect(user_set.user).to be_a Supplejack::User
        expect(user_set.user.name).to eq 'Juanito'
      end
    end

    describe '#attributes' do
      it 'returns a hash of the set attributes' do
        set = Supplejack::UserSet.new
        set.name = 'Dogs'
        set.description = 'Hi'

        expect(set.attributes).to include(name: 'Dogs', description: 'Hi')
      end

      it 'includes an array of :records' do
        set = Supplejack::UserSet.new
        set.records = [{ record_id: 1, position: 1 }]

        expect(set.attributes[:records]).to eq [{ record_id: 1, position: 1 }]
      end
    end

    describe '#api_attributes' do
      it 'only returns the fields that can be stored' do
        supplejack_set.attributes = { count: 1, url: 'Hi' }

        expect(supplejack_set).not_to receive(:count)
        expect(supplejack_set).not_to receive(:url)

        supplejack_set.api_attributes
      end

      it 'should send the featured value' do
        supplejack_set.featured = true

        expect(supplejack_set.api_attributes).to include(featured: true)
      end

      it 'returns a array of records with only id and position' do
        allow(supplejack_set).to receive(:api_records) { [{ record_id: 1, position: 1 }] }

        expect(supplejack_set.api_attributes[:records]).to eq [{ record_id: 1, position: 1 }]
      end
    end

    describe '#items' do
      it 'initializes a item_relation object' do
        expect(supplejack_set.items).to be_a Supplejack::ItemRelation
      end
    end

    describe '#tag_list' do
      it 'returns a comma sepparated list of tags' do
        expect(Supplejack::UserSet.new(tags: %w[dog cat]).tag_list).to eq 'dog, cat'
      end
    end

    describe '#priority' do
      it 'defaults to 1 when is null' do
        expect(Supplejack::UserSet.new.priority).to eq 1
      end

      it 'keeps the value set' do
        expect(Supplejack::UserSet.new(priority: 0).priority).to eq 0
      end
    end

    describe '#favourite?' do
      it 'returns true when the name is Favourites' do
        expect(Supplejack::UserSet.new(name: 'Favourites').favourite?).to be true
      end

      it 'returns false when the name is something else' do
        expect(Supplejack::UserSet.new(name: 'Dogs').favourite?).to be false
      end
    end

    describe '#private?' do
      it 'returns true when the privacy is private' do
        expect(Supplejack::UserSet.new(privacy: 'private').private?).to be true
      end

      it 'returns false when the privacy is something else' do
        expect(Supplejack::UserSet.new(privacy: 'public').private?).to be false
      end
    end

    describe '#public?' do
      it 'returns false when the privacy is private' do
        expect(Supplejack::UserSet.new(privacy: 'private').public?).to be false
      end

      it 'returns true when the privacy is public' do
        expect(Supplejack::UserSet.new(privacy: 'public').public?).to be true
      end
    end

    describe '#hidden?' do
      it 'returns false when the privacy is not hidden' do
        expect(Supplejack::UserSet.new(privacy: 'public').hidden?).to be false
      end

      it 'returns true when the privacy is hidden' do
        expect(Supplejack::UserSet.new(privacy: 'hidden').hidden?).to be true
      end
    end

    describe '#record?' do
      let(:supplejack_set) { Supplejack::UserSet.new(records: [{ record_id: 1, position: 2, title: 'Dogs' }]) }

      it 'returns true when the record is part of the set' do
        expect(supplejack_set.record?(1)).to be true
      end

      it 'returns false when the record is not part of the set' do
        expect(supplejack_set.record?(3)).to be false
      end
    end

    describe '#save' do
      before :each do
        @attributes = { name: 'Dogs', description: 'hi', count: 3 }

        allow(supplejack_set).to receive(:api_attributes) { @attributes }
        allow(supplejack_set).to receive(:api_key) { '123abc' }
      end

      context 'user_set is a new_record' do
        before { allow(supplejack_set).to receive(:new_record?) { true } }

        it 'triggers a POST request to /sets.json' do
          expect(Supplejack::UserSet).to receive(:post).with('/sets', { api_key: '123abc' }, set: @attributes) { { 'set' => { 'id' => 'new-id' } } }

          expect(supplejack_set.save).to be true
        end

        it 'stores the id of the user_set' do
          allow(Supplejack::UserSet).to receive(:post) { { 'set' => { 'id' => 'new-id' } } }

          supplejack_set.save

          expect(supplejack_set.id).to eq 'new-id'
        end

        it 'returns false for anything other that a 200 response' do
          allow(Supplejack::UserSet).to receive(:post).and_raise(RestClient::Forbidden.new)

          expect(supplejack_set.save).to be false
        end
      end

      context 'user_set is not new' do
        before :each do
          allow(supplejack_set).to receive(:new_record?) { false }

          supplejack_set.id = '123'
        end

        it 'triggers a PUT request to /sets/123.json with the user set api_key' do
          expect(Supplejack::UserSet).to receive(:put).with('/sets/123', { api_key: '123abc' }, set: @attributes)

          supplejack_set.save
        end
      end
    end

    describe '#update_attributes' do
      it 'sets the attributes on the user_set' do
        expect(supplejack_set).to receive('attributes=').with(name: 'Mac')

        supplejack_set.update_attributes(name: 'Mac')
      end

      it 'saves the user_set' do
        expect(supplejack_set).to receive(:save)

        supplejack_set.update_attributes(name: 'Mac')
      end
    end

    describe '#attributes=' do
      it 'updates the attributes on the user_set' do
        supplejack_set.attributes = { name: 'Mac' }

        expect(supplejack_set.name).to eq 'Mac'
      end

      it 'should only update passed attributes' do
        supplejack_set.id = '12345'
        supplejack_set.attributes = { name: 'Mac' }

        expect(supplejack_set.id).to eq '12345'
      end

      it 'replaces the records in the ordered form' do
        supplejack_set.attributes = { ordered_records: [9, 1, 5] }

        expect(supplejack_set.records).to eq([{ record_id: 9, position: 1 }, { record_id: 1, position: 2 }, { record_id: 5, position: 3 }])
      end
    end

    describe '#updated_at= and created_at=' do
      %i[created_at updated_at].each do |attr|
        it 'converts a string into a time object' do
          supplejack_set.send("#{attr}=", '2012-08-17T10:01:00+12:00')

          expect(supplejack_set.send(attr)).to be_a Time
        end

        it 'sets nil when the time is incorrect' do
          supplejack_set.send("#{attr}=", '838927587hdfhsjdf')

          expect(supplejack_set.send(attr)).to be nil
        end

        it 'should accept a Time object too' do
          @time = Time.now
          supplejack_set.send("#{attr}=", @time)

          expect(supplejack_set.send(attr)).to eq @time
        end
      end
    end

    describe '#api_records' do
      it 'generates a hash of records with position and record_id' do
        allow(supplejack_set).to receive(:records) { [{ title: 'Hi', record_id: 1, position: 1 }] }

        expect(supplejack_set.api_records).to eq [{ record_id: 1, position: 1 }]
      end

      it 'removes records without a record_id' do
        allow(supplejack_set).to receive(:records) { [{ title: 'Hi', record_id: 1, position: 1 }, { position: 6 }] }

        expect(supplejack_set.api_records).to eq [{ record_id: 1, position: 1 }]
      end

      it 'handles nil records' do
        allow(supplejack_set).to receive(:records) { nil }

        expect(supplejack_set.api_records).to eq []
      end
    end

    describe '#ordered_records_from_array' do
      it 'returns a hash with positons and record_ids' do
        expect(supplejack_set.ordered_records_from_array([9, 1, 5])).to eq([{ record_id: 9, position: 1 }, { record_id: 1, position: 2 }, { record_id: 5, position: 3 }])
      end
    end

    describe '#new_record?' do
      it 'returns true when the user_set doesn\'t have a id' do
        expect(Supplejack::UserSet.new.new_record?).to be true
      end

      it 'returns false when the user_set has a id' do
        expect(Supplejack::UserSet.new(id: '1234abc').new_record?).to be false
      end
    end

    describe '#destroy' do
      before :each do
        allow(supplejack_set).to receive(:api_key) { '123abc' }
        allow(supplejack_set).to receive(:id) { '999' }
      end

      it 'executes a delete request to the API with the user set api_key' do
        expect(Supplejack::UserSet).to receive(:delete).with('/sets/999', api_key: '123abc')

        expect(supplejack_set.destroy).to be true
      end

      it 'returns false when the response is not a 200' do
        allow(Supplejack::UserSet).to receive(:delete).and_raise(RestClient::Forbidden.new)

        expect(supplejack_set.destroy).to be false
        expect(supplejack_set.errors).to eq 'Forbidden'
      end

      it 'returns false when it is a new user set' do
        allow(supplejack_set).to receive(:new_record?) { true }

        expect(Supplejack::UserSet).not_to receive(:delete)
        expect(supplejack_set.destroy).to be false
      end
    end

    describe '#reload' do
      let(:supplejack_set) { Supplejack::UserSet.new(id: '123456') }

      before :each do
        allow(Supplejack::UserSet).to receive(:get).with('/sets/123456') { { 'set' => { 'id' => 'abc' } } }
      end

      it 'fetches the set from the api and repopulates the set' do
        supplejack_set.reload

        expect(supplejack_set.id).to eq 'abc'
      end

      it 'removes the existing @items relation' do
        supplejack_set.items
        supplejack_set.reload

        expect(supplejack_set.instance_variable_get('@items')).to be nil
      end
    end

    describe '#viewable_by?' do
      it 'returns true when the user_set is public' do
        allow(supplejack_set).to receive(:public?) { true }

        expect(supplejack_set.viewable_by?(nil)).to be true
      end

      it 'returns true when the user_set is hidden' do
        allow(supplejack_set).to receive(:hidden?) { true }

        expect(supplejack_set.viewable_by?(nil)).to be true
      end

      context 'private set' do
        before { allow(supplejack_set).to receive(:public?) { false } }

        it 'returns false when the user is not present' do
          expect(supplejack_set.viewable_by?(nil)).to be false
        end

        it 'returns true when the user has the same api_key as the user_set' do
          user = double(:user, api_key: '12345')
          supplejack_set.api_key = '12345'

          expect(supplejack_set.viewable_by?(user)).to be true
        end

        it 'returns false if both the api_key in the user and the set are nil' do
          user = double(:user, api_key: nil)
          supplejack_set.api_key = nil

          expect(supplejack_set.viewable_by?(user)).to be false
        end
      end
    end

    describe '#owned_by?' do
      let(:user) { double(:user, api_key: '123456') }

      it 'returns true when the users api_key is the same as the set\'s' do
        allow(supplejack_set).to receive(:api_key) { '123456' }

        expect(supplejack_set.owned_by?(user)).to be true
      end

      it 'returns false when the set and user have different api_keys' do
        allow(supplejack_set).to receive(:api_key) { '666' }

        expect(supplejack_set.owned_by?(user)).to be false
      end

      it 'returns false when both keys are nil' do
        allow(user).to receive(:api_key) { nil }

        allow(supplejack_set).to receive(:api_key) { nil }

        expect(supplejack_set.owned_by?(user)).to be false
      end
    end

    describe '#set_record_id?' do
      before { @set = supplejack_set }

      it 'should return the record_id' do
        allow(@set).to receive(:record).and_return('record_id' => 123)

        expect(@set.set_record_id).to eq 123
      end

      it 'should return nil if the set doesn\'t have a record' do
        expect(@set.set_record_id).to be nil
      end
    end

    describe '#find' do
      before :each do
        @set = supplejack_set
        allow(Supplejack::UserSet).to receive(:new) { @set }
      end

      it 'fetches the set from the api' do
        expect(Supplejack::UserSet).to receive(:get).with('/sets/123abc', {})

        Supplejack::UserSet.find('123abc')
      end

      it 'initializes a UserSet object' do
        expect(Supplejack::UserSet).to receive(:new).with(id: '123abc', name: 'Dogs', count: 0).and_return(@set)

        set = Supplejack::UserSet.find('123abc')

        expect(set.class).to eq Supplejack::UserSet
      end

      it 'initializes the UserSet and sets the user api_key' do
        set = Supplejack::UserSet.find('123abc', '98765')

        expect(set.api_key).to eq '98765'
      end

      it 'raises a Supplejack::SetNotFound' do
        allow(Supplejack::UserSet).to receive(:get).and_raise(RestClient::ResourceNotFound)

        expect { Supplejack::UserSet.find('123') }.to raise_error(Supplejack::SetNotFound)
      end
    end

    describe '#public_sets' do
      before :each do
        allow(Supplejack::UserSet).to receive(:get) { { 'sets' => [{ 'id' => '123', 'name' => 'Dog' }] } }
      end

      it 'fetches the public sets from the api' do
        expect(Supplejack::UserSet).to receive(:get).with('/sets/public', page: 1, per_page: 100)

        Supplejack::UserSet.public_sets
      end

      it 'returns an array of user set objects' do
        @set = supplejack_set
        expect(Supplejack::UserSet).to receive(:new).once.with('id' => '123', 'name' => 'Dog') { @set }

        sets = Supplejack::UserSet.public_sets

        expect(sets).to be_a Array
        expect(sets.size).to eq 1
      end

      it 'sends pagination information' do
        expect(Supplejack::UserSet).to receive(:get).with('/sets/public', page: 2, per_page: 100)

        Supplejack::UserSet.public_sets(page: 2)
      end
    end

    describe '#featured_sets' do
      before :each do
        allow(Supplejack::UserSet).to receive(:get) { { 'sets' => [{ 'id' => '123', 'name' => 'Dog' }] } }
      end

      it 'fetches the public sets from the api' do
        expect(Supplejack::UserSet).to receive(:get).with('/sets/featured')

        Supplejack::UserSet.featured_sets
      end

      it 'returns an array of user set objects' do
        @set = supplejack_set

        expect(Supplejack::UserSet).to receive(:new).once.with('id' => '123', 'name' => 'Dog') { @set }
        sets = Supplejack::UserSet.featured_sets

        expect(sets).to be_a Array
        expect(sets.size).to eq 1
      end
    end
  end
end
