# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe Item do
    describe '#initialize' do
      it 'accepts a hash with string keys' do
        expect(Supplejack::Item.new('record_id' => '123').record_id).to eq '123'
      end

      it 'handles nil attributes' do
        expect(Supplejack::Item.new(nil).record_id).to be_nil
      end

      it 'should initialize the attribute :record_id' do
        expect(Supplejack::Item.new(record_id: 'value').send(:record_id)).to eq 'value'
      end
    end

    describe '#attributes' do
      it 'should not include the api_key' do
        expect(Supplejack::Item.new(api_key: '1234').attributes).not_to have_key(:api_key)
      end

      it 'should not include the user_set_id' do
        expect(Supplejack::Item.new(user_set_id: '1234').attributes).not_to have_key(:user_set_id)
      end
    end

    describe '#save' do
      let(:item) { Supplejack::Item.new(record_id: 1, title: 'Dogs', user_set_id: '1234', api_key: 'abc') }

      it 'triggers a post request to create a set_item with the set api_key' do
        expect(item).to receive(:post).with('/sets/1234/records', { api_key: 'abc' }, record: { record_id: 1 })
        
        expect(item.save).to be true
      end

      it 'sends the position when set' do
        expect(item).to receive(:post).with('/sets/1234/records', { api_key: 'abc' }, record: { record_id: 1, position: 3 })
        item.position = 3

        expect(item.save).to be true
      end

      context 'HTTP error is raised' do
        before { allow(item).to receive(:post).and_raise(RestClient::Forbidden.new) }

        it 'returns false when a HTTP error is raised' do
          expect(item.save).to be false
        end

        it 'stores the error when a error is raised' do
          item.save

          expect(item.errors).to eq 'Forbidden'
        end
      end
    end

    describe '#destroy' do
      let(:item) { Supplejack::Item.new(user_set_id: '1234', api_key: 'abc', record_id: 5) }

      it 'triggers a delete request with the user_set api_key' do
        expect(item).to receive(:delete).with('/sets/1234/records/5', api_key: 'abc')
        
        item.destroy
      end

      context 'HTTP error is raised' do
        before { allow(item).to receive(:delete).and_raise(RestClient::Forbidden.new) }

        it 'returns false when a HTTP error is raised' do
          expect(item.destroy).to be false
        end

        it 'stores the error when a error is raised' do
          item.destroy

          expect(item.errors).to eq 'Forbidden'
        end
      end
    end

    describe '#date' do
      it 'returns a Time object' do
        item = Supplejack::Item.new(date: ['1977-01-01T00:00:00.000Z'])

        expect(item.date).to eq Time.parse('1977-01-01T00:00:00.000Z')
      end

      it 'returns nil when the date is not in the correct format' do
        item = Supplejack::Item.new(date: ['afsdfgsdfg'])

        expect(item.date).to be nil
      end
    end

    describe '#method_missing' do
      it 'returns nil for any unknown attribute' do
        expect(Supplejack::Item.new.non_existent_method).to be nil
      end
    end
  end
end
