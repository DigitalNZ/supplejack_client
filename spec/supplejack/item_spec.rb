require 'spec_helper'

module Supplejack
	describe Item do

    describe '#initialize' do
      it 'accepts a hash of attributes' do
        Supplejack::Item.new({record_id: '123', name: 'Dog'})
      end

      it 'accepts a hash with string keys' do
        Supplejack::Item.new({'record_id' => '123'}).record_id.should eq '123'
      end

      it 'handles nil attributes' do
        Supplejack::Item.new(nil).record_id.should be_nil
      end

      [:record_id].each do |attribute|
        it 'should initialize the attribute #{attribute}' do
          Supplejack::Item.new({attribute => 'value'}).send(attribute).should eq 'value'
        end
      end
    end

    describe '#attributes' do
      it 'should not include the api_key' do
        Supplejack::Item.new({api_key: '1234'}).attributes.should_not have_key(:api_key)
      end

      it 'should not include the user_set_id' do
        Supplejack::Item.new({user_set_id: '1234'}).attributes.should_not have_key(:user_set_id)
      end
    end

    describe '#save' do
      let(:item) { Supplejack::Item.new(record_id: 1, title: 'Dogs', user_set_id: '1234', api_key: 'abc') }

      it 'triggers a post request to create a set_item with the set api_key' do
        item.should_receive(:post).with('/sets/1234/records', {api_key: 'abc'}, {record: {record_id: 1}})
        item.save.should be_true
      end

      it 'sends the position when set' do
        item.should_receive(:post).with('/sets/1234/records', {api_key: 'abc'}, {record: {record_id: 1, position: 3}})
        item.position = 3
        item.save.should be_true
      end

      context 'HTTP error is raised' do
        before :each do
          item.stub(:post).and_raise(RestClient::Forbidden.new)
        end

        it 'returns false when a HTTP error is raised' do
          item.save.should be_false
        end

        it 'stores the error when a error is raised' do
          item.save
          item.errors.should eq 'Forbidden'
        end
      end
    end

    describe '#destroy' do
      let(:item) { Supplejack::Item.new(user_set_id: '1234', api_key: 'abc', record_id: 5) }

      it 'triggers a delete request with the user_set api_key' do
        item.should_receive(:delete).with('/sets/1234/records/5', {api_key: 'abc'})
        item.destroy
      end

      context 'HTTP error is raised' do
        before :each do
          item.stub(:delete).and_raise(RestClient::Forbidden.new)
        end

        it 'returns false when a HTTP error is raised' do
          item.destroy.should be_false
        end

        it 'stores the error when a error is raised' do
          item.destroy
          item.errors.should eq 'Forbidden'
        end
      end
    end

    describe '#date' do
      it 'returns a Time object' do
        item = Supplejack::Item.new(date: ['1977-01-01T00:00:00.000Z'])
        item.date.should eq Time.parse('1977-01-01T00:00:00.000Z')
      end

      it 'returns nil when the date is not in the correct format' do
        item = Supplejack::Item.new(date: ['afsdfgsdfg'])
        item.date.should be_nil
      end
    end

    describe '#method_missing' do
      it 'returns nil for any unknown attribute' do
        Supplejack::Item.new.non_existent_method.should be_nil
      end
    end
  end
end