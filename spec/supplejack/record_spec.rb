# frozen_string_literal: true

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

class Search < Supplejack::Search
  def initialize(params = {})
    super
    self.or = { type: ['Person'] }
  end
end

class SpecialSearch < Supplejack::Search
  def initialize(params = {})
    super(params)
    api_params[:and].delete(:format) if api_params && api_params[:and]
  end
end

module Supplejack
  describe Record do
    it 'initializes its attributes from a JSON string' do
      record = SupplejackRecord.new(%({"type": "Person", "location": "NZ"}))

      expect(record.attributes).to eq(type: 'Person', location: 'NZ')
    end

    it 'handles nil params' do
      record = SupplejackRecord.new(nil)

      expect(record.attributes).to eq({})
    end

    it 'handles a string as params' do
      record = SupplejackRecord.new('')

      expect(record.attributes).to eq({})
    end

    it 'handles a array as params' do
      record = SupplejackRecord.new([])

      expect(record.attributes).to eq({})
    end

    it 'raises a NoMethodError for every method call that doesn\'t have a key in the attributes' do
      record = SupplejackRecord.new
      expect { record.something }.to raise_error(NoMethodError)
    end

    it 'returns the value when is present in the attributes' do
      record = SupplejackRecord.new(weird_method: 'Something')

      expect(record.weird_method).to eq 'Something'
    end

    describe 'id' do
      it 'returns the record_id' do
        record = SupplejackRecord.new('record_id' => '95')

        expect(record.id).to eq 95
      end

      it 'returns the id' do
        record = SupplejackRecord.new('id' => '96')

        expect(record.id).to eq 96
      end
    end

    describe '#title' do
      it 'returns the title attribute value' do
        expect(SupplejackRecord.new(title: 'Dogs').title).to eq 'Dogs'
      end

      it 'returns "Untitled" for records without a title' do
        expect(SupplejackRecord.new(title: nil).title).to eq 'Untitled'
      end
    end

    describe '#metadata' do
      it 'returns an array of hashes with special fields their values and schemas' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:location] } })

        record = SupplejackRecord.new(location: 'Wellington')
        expect(record.metadata).to include(name: 'location', schema: 'admin', value: 'Wellington')
      end

      it 'returns an array of hashes with special fields their values and schemas for multiple special_fields configured' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:location] }, supplejack_user: { fields: [:description] } })

        record = SupplejackRecord.new(location: 'Wellington', description: 'Some description')

        expect(record.metadata).to include({ name: 'location', schema: 'admin', value: 'Wellington' }, name: 'description', schema: 'supplejack_user', value: 'Some description')
      end

      it 'return no metadata for inexistent attribtues' do
        allow(Supplejack).to receive(:supplejack_fields).and_return([:description])

        record = SupplejackRecord.new(location: 'Wellington')
        expect(record.metadata.empty?).to be true
      end

      it 'returns multiple elements for a multi value field' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:location] } })

        record = SupplejackRecord.new(location: %w[Wellington Auckland])

        expect(record.metadata).to include({ name: 'location', schema: 'admin', value: 'Wellington' }, name: 'location', schema: 'admin', value: 'Auckland')
      end

      it 'returns a empty array for a empty field' do
        allow(Supplejack).to receive(:supplejack_fields).and_return([:location])

        record = SupplejackRecord.new(location: nil)

        expect(record.metadata.empty?).to be true
      end

      it 'works for boolean fields too' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:is_human] } })

        record = SupplejackRecord.new(is_human: true)

        expect(record.metadata).to include(name: 'is_human', schema: 'admin', value: true)
      end

      it 'works for boolean fields when they are false' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:is_human] } })

        record = SupplejackRecord.new(is_human: false)

        expect(record.metadata).to include(name: 'is_human', schema: 'admin', value: false)
      end

      it 'returns names with the schema removed' do
        allow(Supplejack).to receive(:special_fields).and_return({ admin: { fields: [:admin_identifier] } })

        record = SupplejackRecord.new(admin_identifier: 'sj:IE1174615')

        expect(record.metadata).to include(name: 'identifier', schema: 'admin', value: 'sj:IE1174615')
      end
    end

    describe '#single_value_methods' do
      before { Supplejack.single_value_methods = [:description] }

      it 'converts values defined in the single_value_methods to a string' do
        record = SupplejackRecord.new('description' => %w[One Two])

        expect(record.description).to eq 'One'
      end

      it 'returns the string if is already a string' do
        record = SupplejackRecord.new('description' => 'One')

        expect(record.description).to eq 'One'
      end
    end

    %i[next_record previous_record next_page previous_page].each do |attr|
      describe attr.to_s do
        it "returns the #{attr}" do
          record = SupplejackRecord.new(attr => 1)

          expect(record.send(attr)).to eq 1
        end

        it 'returns the nil' do
          record = SupplejackRecord.new({})

          expect(record.send(attr)).to be_nil
        end
      end
    end

    describe '#find' do
      context 'with id' do
        it 'raises a Supplejack::RecordNotFound' do
          allow(SupplejackRecord).to receive(:get).and_raise(RestClient::ResourceNotFound)

          expect { SupplejackRecord.find(1) }.to raise_error(Supplejack::RecordNotFound)
        end

        it 'raises a Supplejack::MalformedRequest' do
          expect { SupplejackRecord.find('replace_this') }.to raise_error(Supplejack::MalformedRequest)
        end

        it 'requests the record from the API' do
          allow(SupplejackRecord).to receive(:get).with('/records/1', fields: 'default').and_return('record' => {})

          SupplejackRecord.find(1)
        end

        it 'initializes a new SupplejackRecord object' do
          allow(SupplejackRecord).to receive(:get).and_return('record' => { 'record_id' => '1', 'title' => 'Wellington' })
          record = SupplejackRecord.find(1)

          expect(record.class).to eq SupplejackRecord
          expect(record.title).to eq 'Wellington'
        end

        it 'send the fields defined in the configuration' do
          allow(Supplejack).to receive(:fields).and_return(%i[verbose default])
          allow(SupplejackRecord).to receive(:get).with('/records/1', fields: 'verbose,default').and_return('record' => {})

          SupplejackRecord.find(1)
        end

        it 'sets the correct search options' do
          allow(SupplejackRecord).to receive(:get).with('/records/1', hash_including(search: hash_including(text: 'dog'))).and_return('record' => {})

          SupplejackRecord.find(1, text: 'dog')
        end

        context 'when using a special search klass' do
          let(:search) { ::Search.new }

          it 'uses the specified search klass' do
            allow(SupplejackRecord).to receive(:get).and_return({ 'record' => {} })
            allow(Supplejack).to receive(:search_klass).and_return('Search')
            allow(::Search).to receive(:new).with(i: { location: 'Wellington' }).and_return(search)

            SupplejackRecord.find(1, i: { location: 'Wellington' })
          end

          it 'uses the default search klass' do
            allow(SupplejackRecord).to receive(:get).and_return({ 'record' => {} })
            allow(Supplejack).to receive(:search_klass).and_return(nil)
            allow(Supplejack::Search).to receive(:new).with(i: { location: 'Wellington' }).and_return(search)

            SupplejackRecord.find(1, i: { location: 'Wellington' })
          end

          it 'sends the params from the subclassed search to the API' do
            allow(Supplejack).to receive(:search_klass).and_return('Search')
            allow(SupplejackRecord).to receive(:get).with('/records/1', hash_including(search: hash_including(and: { name: 'John' }, or: { type: ['Person'] }))).and_return('record' => {})

            SupplejackRecord.find(1, i: { name: 'John' })
          end

          it 'sends any changes to the api_params made on the subclassed search object' do
            allow(Supplejack).to receive(:search_klass).and_return('SpecialSearch')
            allow(SupplejackRecord).to receive(:get).with('/records/1', hash_including(search: hash_including(and: {}))).and_return('record' => {})

            SupplejackRecord.find(1, i: { format: 'Images' })
          end
        end
      end

      context 'with multiple ids' do
        it 'sends a request to /records/multiple endpoint with an array of record ids' do
          allow(SupplejackRecord).to receive(:get).with('/records/multiple', record_ids: [1, 2], fields: 'default').and_return('records' => [])

          SupplejackRecord.find([1, 2])
        end

        it 'initializes multiple SupplejackRecord objects' do
          allow(SupplejackRecord).to receive(:get).and_return('records' => [{ 'id' => '1' }, { 'id' => '2' }])
          records = SupplejackRecord.find([1, 2])

          expect(records.size).to eq 2
          expect(records.first.class).to eq SupplejackRecord
        end

        it 'requests the fields in Supplejack.fields' do
          allow(Supplejack).to receive(:fields).and_return(%i[verbose description])
          allow(SupplejackRecord).to receive(:get).with('/records/multiple', record_ids: [1, 2], fields: 'verbose,description').and_return('records' => [])

          SupplejackRecord.find([1, 2])
        end
      end
    end
  end
end
