# frozen_string_literal: true

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

module Supplejack
  describe UserSet do
    let(:supplejack_set) { described_class.new(records: [{ record_id: 1, position: 2, title: 'Dogs' }]) }

    before do
      allow(Supplejack).to receive(:enable_caching).and_return(false)
      allow(described_class).to receive(:get).and_return({ 'set' => { id: '123abc', name: 'Dogs', count: 0 } })
    end

    describe '#initialize' do
      %i[id name description privacy url priority count tag_list featured approved].each do |attribute|
        it "initializes the #{attribute}" do
          expect(described_class.new(attribute => 'value').send(attribute)).to eq 'value'
        end
      end

      it 'converts the updated_at into a time object' do
        expect(described_class.new(updated_at: '2012-08-17T10:01:00+12:00').updated_at).to be_a Time
      end

      it 'symbolizes the attributes hash' do
        expect(described_class.new('name' => 'Dog').name).to eq 'Dog'
      end

      it 'initializes a user object' do
        user_set = described_class.new(user: { name: 'Juanito' })

        expect(user_set.user).to be_a Supplejack::User
        expect(user_set.user.name).to eq 'Juanito'
      end
    end

    describe '#attributes' do
      it 'returns a hash of the set attributes' do
        set = described_class.new
        set.name = 'Dogs'
        set.description = 'Hi'

        expect(set.attributes).to include(name: 'Dogs', description: 'Hi')
      end

      it 'includes an array of :records' do
        set = described_class.new
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

      it 'sends the featured value' do
        supplejack_set.featured = true

        expect(supplejack_set.api_attributes).to include(featured: true)
      end

      it 'returns a array of records with only id and position' do
        allow(supplejack_set).to receive(:api_records).and_return([{ record_id: 1, position: 1 }])

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
        expect(described_class.new(tags: %w[dog cat]).tag_list).to eq 'dog, cat'
      end
    end

    describe '#priority' do
      it 'defaults to 1 when is null' do
        expect(described_class.new.priority).to eq 1
      end

      it 'keeps the value set' do
        expect(described_class.new(priority: 0).priority).to eq 0
      end
    end

    describe '#favourite?' do
      it 'returns true when the name is Favourites' do
        expect(described_class.new(name: 'Favourites').favourite?).to be true
      end

      it 'returns false when the name is something else' do
        expect(described_class.new(name: 'Dogs').favourite?).to be false
      end
    end

    describe '#private?' do
      it 'returns true when the privacy is private' do
        expect(described_class.new(privacy: 'private').private?).to be true
      end

      it 'returns false when the privacy is something else' do
        expect(described_class.new(privacy: 'public').private?).to be false
      end
    end

    describe '#public?' do
      it 'returns false when the privacy is private' do
        expect(described_class.new(privacy: 'private').public?).to be false
      end

      it 'returns true when the privacy is public' do
        expect(described_class.new(privacy: 'public').public?).to be true
      end
    end

    describe '#hidden?' do
      it 'returns false when the privacy is not hidden' do
        expect(described_class.new(privacy: 'public').hidden?).to be false
      end

      it 'returns true when the privacy is hidden' do
        expect(described_class.new(privacy: 'hidden').hidden?).to be true
      end
    end

    describe '#record?' do
      let(:supplejack_set) { described_class.new(records: [{ record_id: 1, position: 2, title: 'Dogs' }]) }

      it 'returns true when the record is part of the set' do
        expect(supplejack_set.record?(1)).to be true
      end

      it 'returns false when the record is not part of the set' do
        expect(supplejack_set.record?(3)).to be false
      end
    end

    describe '#save' do
      let(:attributes) { { name: 'Dogs', description: 'hi', count: 3 } }

      before do
        allow(supplejack_set).to receive(:api_attributes).and_return(attributes)
        allow(supplejack_set).to receive(:api_key).and_return('123abc')
      end

      context 'when user_set is a new_record' do
        before { allow(supplejack_set).to receive(:new_record?).and_return(true) }

        it 'triggers a POST request to /sets.json' do
          allow(described_class).to receive(:post).with('/sets', { api_key: '123abc' }, set: attributes).and_return({ 'set' => { 'id' => 'new-id' } })

          expect(supplejack_set.save).to be true
        end

        it 'stores the id of the user_set' do
          allow(described_class).to receive(:post).and_return({ 'set' => { 'id' => 'new-id' } })

          supplejack_set.save

          expect(supplejack_set.id).to eq 'new-id'
        end

        it 'returns false for anything other that a 200 response' do
          allow(described_class).to receive(:post).and_raise(RestClient::Forbidden.new)

          expect(supplejack_set.save).to be false
        end
      end

      context 'when user_set is not new' do
        before do
          allow(supplejack_set).to receive(:new_record?).and_return(false)

          supplejack_set.id = '123'
        end

        it 'triggers a PUT request to /sets/123.json with the user set api_key' do
          expect(described_class).to receive(:put).with('/sets/123', { api_key: '123abc' }, set: attributes)

          supplejack_set.save
        end
      end
    end

    describe '#update_attributes' do
      it 'sets the attributes on the user_set' do
        expect(supplejack_set).to receive('attributes=').with({ name: 'Mac' })

        supplejack_set.update_attributes({ name: 'Mac' })
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

      it 'updates only the attributes passed' do
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

        it 'accepts a Time object too' do
          time = Time.now
          supplejack_set.send("#{attr}=", time)

          expect(supplejack_set.send(attr)).to eq time
        end
      end
    end

    describe '#api_records' do
      it 'generates a hash of records with position and record_id' do
        allow(supplejack_set).to receive(:records).and_return([{ title: 'Hi', record_id: 1, position: 1 }])

        expect(supplejack_set.api_records).to eq [{ record_id: 1, position: 1 }]
      end

      it 'removes records without a record_id' do
        allow(supplejack_set).to receive(:records).and_return([{ title: 'Hi', record_id: 1, position: 1 }, { position: 6 }])

        expect(supplejack_set.api_records).to eq [{ record_id: 1, position: 1 }]
      end

      it 'handles nil records' do
        allow(supplejack_set).to receive(:records).and_return(nil)

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
        expect(described_class.new.new_record?).to be true
      end

      it 'returns false when the user_set has a id' do
        expect(described_class.new(id: '1234abc').new_record?).to be false
      end
    end

    describe '#destroy' do
      before do
        allow(supplejack_set).to receive(:api_key).and_return('123abc')
        allow(supplejack_set).to receive(:id).and_return('999')
      end

      it 'executes a delete request to the API with the user set api_key' do
        expect(described_class).to receive(:delete).with('/sets/999', api_key: '123abc')

        expect(supplejack_set.destroy).to be true
      end

      it 'returns false when the response is not a 200' do
        allow(described_class).to receive(:delete).and_raise(RestClient::Forbidden.new)

        expect(supplejack_set.destroy).to be false
        expect(supplejack_set.errors).to eq 'Forbidden'
      end

      it 'returns false when it is a new user set' do
        allow(supplejack_set).to receive(:new_record?).and_return(true)

        expect(described_class).not_to receive(:delete)
        expect(supplejack_set.destroy).to be false
      end
    end

    describe '#reload' do
      let(:supplejack_set) { described_class.new(id: '123456') }

      before do
        allow(described_class).to receive(:get).with('/sets/123456').and_return({ 'set' => { 'id' => 'abc' } })
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
        allow(supplejack_set).to receive(:public?).and_return(true)

        expect(supplejack_set.viewable_by?(nil)).to be true
      end

      it 'returns true when the user_set is hidden' do
        allow(supplejack_set).to receive(:hidden?).and_return(true)

        expect(supplejack_set.viewable_by?(nil)).to be true
      end

      context 'when set is private' do
        before { allow(supplejack_set).to receive(:public?).and_return(false) }

        it 'returns false when the user is not present' do
          expect(supplejack_set.viewable_by?(nil)).to be false
        end

        it 'returns true when the user has the same api_key as the user_set' do
          user = instance_double(Supplejack::User, api_key: '12345')
          supplejack_set.api_key = '12345'

          expect(supplejack_set.viewable_by?(user)).to be true
        end

        it 'returns false if both the api_key in the user and the set are nil' do
          user = instance_double(Supplejack::User, api_key: nil)
          supplejack_set.api_key = nil

          expect(supplejack_set.viewable_by?(user)).to be false
        end
      end
    end

    describe '#owned_by?' do
      let(:user) { instance_double(Supplejack::User, api_key: '123456') }

      it 'returns true when the users api_key is the same as the set\'s' do
        allow(supplejack_set).to receive(:api_key).and_return('123456')

        expect(supplejack_set.owned_by?(user)).to be true
      end

      it 'returns false when the set and user have different api_keys' do
        allow(supplejack_set).to receive(:api_key).and_return('666')

        expect(supplejack_set.owned_by?(user)).to be false
      end

      it 'returns false when both keys are nil' do
        allow(user).to receive(:api_key).and_return(nil)
        allow(supplejack_set).to receive(:api_key).and_return(nil)

        expect(supplejack_set.owned_by?(user)).to be false
      end
    end

    describe '#set_record_id?' do
      it 'returns the record_id' do
        allow(supplejack_set).to receive(:record).and_return('record_id' => 123)

        expect(supplejack_set.set_record_id).to eq 123
      end

      it 'returns nil if the set doesn\'t have a record' do
        expect(supplejack_set.set_record_id).to be nil
      end
    end

    describe '#find' do
      before do
        @set = supplejack_set
        allow(described_class).to receive(:new) { @set }
      end

      it 'fetches the set from the api' do
        expect(described_class).to receive(:get).with('/sets/123abc', {})

        described_class.find('123abc')
      end

      it 'initializes a UserSet object' do
        allow(described_class).to receive(:new).with(id: '123abc', name: 'Dogs', count: 0).and_return(@set)

        set = described_class.find('123abc')

        expect(set.class).to eq described_class
      end

      it 'initializes the UserSet and sets the user api_key' do
        set = described_class.find('123abc', '98765')

        expect(set.api_key).to eq '98765'
      end

      it 'raises a Supplejack::SetNotFound' do
        allow(described_class).to receive(:get).and_raise(RestClient::ResourceNotFound)

        expect { described_class.find('123') }.to raise_error(Supplejack::SetNotFound)
      end
    end

    describe '#public_sets' do
      before do
        allow(described_class).to receive(:get).and_return({ 'sets' => [{ 'id' => '123', 'name' => 'Dog' }] })
      end

      it 'fetches the public sets from the api' do
        expect(described_class).to receive(:get).with('/sets/public', { page: 1, per_page: 100 })

        described_class.public_sets
      end

      it 'returns an array of user set objects' do
        set = supplejack_set
        expect(described_class).to receive(:new).once.with({ 'id' => '123', 'name' => 'Dog' }) { set }

        sets = described_class.public_sets

        expect(sets).to be_a Array
      end

      it 'sends pagination information' do
        expect(described_class).to receive(:get).with('/sets/public', { page: 2, per_page: 100 })

        described_class.public_sets(page: 2)
      end
    end

    describe '#featured_sets' do
      before do
        allow(described_class).to receive(:get).and_return({ 'sets' => [{ 'id' => '123', 'name' => 'Dog' }] })
      end

      it 'fetches the public sets from the api' do
        expect(described_class).to receive(:get).with('/sets/featured')

        described_class.featured_sets
      end

      it 'returns an array of user set objects' do
        set = supplejack_set

        expect(described_class).to receive(:new).once.with({ 'id' => '123', 'name' => 'Dog' }) { set }
        sets = described_class.featured_sets

        expect(sets).to be_a Array
      end
    end
  end
end
