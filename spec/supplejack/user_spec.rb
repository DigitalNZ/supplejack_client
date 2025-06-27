# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe User do
    let(:user) { described_class.new('id' => 'abc', 'authentication_token' => '12345') }
    let(:relation) { Supplejack::UserSetRelation.new(user) }

    before do
      allow(described_class).to receive(:get).and_return({ 'user' => { 'id' => 'abc', 'authentication_token' => '12345' } })
    end

    describe '#initialize' do
      it 'initializes the user attributes' do
        expect(described_class.new('authentication_token' => '12345').api_key).to eq '12345'
      end

      it 'initializes the user name' do
        expect(described_class.new('name' => 'Juanito').name).to eq 'Juanito'
      end

      it 'initializes the sets attributes' do
        expect(described_class.new('sets' => [{ name: 'Dogs' }]).sets_attributes).to eq [{ name: 'Dogs' }]
      end

      it 'initializes the use_own_api attribute' do
        expect(described_class.new('use_own_api_key' => true).use_own_api_key).to be true
      end

      it 'initializes the regenerate_api_key attribute' do
        expect(described_class.new('regenerate_api_key' => true).regenerate_api_key).to be true
      end
    end

    describe '#sets' do
      it 'initializes a Supplejack::UserSetRelation object' do
        expect(user.sets).to be_a Supplejack::UserSetRelation
      end
    end

    describe '#save' do
      it 'executes a put request with the user attribtues' do
        allow(user).to receive(:api_attributes).and_return({ username: 'John', email: 'john@boost.co.nz' })

        expect(described_class).to receive(:put).with('/users/12345', {}, { username: 'John', email: 'john@boost.co.nz' })

        expect(user.save).to be true
      end

      context 'when regenerate_api_key is true' do
        before { user.regenerate_api_key = true }

        it 'posts a nil authentication_token attribute so it is regenerated' do
          expect(described_class).to receive(:put).with('/users/12345', {}, hash_including(authentication_token: nil))

          user.save
        end

        it 'sets the regenerated api_key on the user' do
          allow(described_class).to receive(:put).and_return('user' => { 'id' => '525f7a2df6941993e2000004', 'name' => nil, 'username' => nil, 'email' => nil, 'api_key' => '71H5yPsxVhDmsjmj1NJW' })

          user.save

          expect(user.instance_variable_get('@api_key')).to eq '71H5yPsxVhDmsjmj1NJW'
        end
      end

      it 'returns false when a error ocurred' do
        allow(described_class).to receive(:put).and_raise(RestClient::Forbidden)

        expect(user.save).to be false
      end
    end

    describe '#destroy' do
      it 'executes a delete request with the admin key' do
        allow(Supplejack).to receive(:api_key).and_return('admin_key')

        expect(described_class).to receive(:delete).with('/users/abc')

        expect(user.destroy).to be true
      end

      it 'returns false if there is a exception' do
        allow(described_class).to receive(:delete).and_raise(RestClient::Forbidden)

        expect(user.destroy).to be false
      end
    end

    describe '#api_attributes' do
      it 'returns the name, username, email and encrypted_password' do
        user = described_class.new(name: 'John', username: 'Johnny', email: 'john@boost.co.nz', encrypted_password: 'xyz', api_key: '12345')

        expect(user.api_attributes).to eq(name: 'John', username: 'Johnny', email: 'john@boost.co.nz', encrypted_password: 'xyz')
      end

      it 'doesn\'t return the attribute if not present' do
        expect(user.api_attributes).not_to include(:name)
      end

      context 'when regenerate_api_key is true' do
        let(:user) { described_class.new(api_key: '12345', regenerate_api_key: true) }

        it 'returns a nil authentication_token' do
          expect(user.api_attributes).to have_key(:authentication_token)

          expect(user.api_attributes[:authentication_token]).to be_nil
        end
      end

      it 'returns the sets_attributes' do
        user = described_class.new(sets: [{ name: 'Dogs', privacy: 'hidden' }])

        expect(user.api_attributes[:sets]).to eq [{ name: 'Dogs', privacy: 'hidden' }]
      end
    end

    describe '#use_own_api_key?' do
      it 'returns false by default' do
        expect(described_class.new.use_own_api_key?).to be false
      end

      it 'returns true' do
        expect(described_class.new('use_own_api_key' => true).use_own_api_key?).to be true
      end
    end

    describe '#regenerate_api_key?' do
      it 'returns false by default' do
        expect(described_class.new.regenerate_api_key?).to be false
      end

      it 'returns true' do
        expect(described_class.new('regenerate_api_key' => true).regenerate_api_key?).to be true
      end
    end

    describe '.find' do
      it 'fetches the user from the api' do
        expect(described_class).to receive(:get).with('/users/12345')

        described_class.find('12345')
      end

      it 'initializes a user with the response' do
        expect(described_class).to receive(:new).with({ 'id' => 'abc', 'authentication_token' => '12345' })

        described_class.find('12345')
      end
    end

    describe '.create' do
      let(:attributes) { { email: 'dev@boost.com', name: 'dev', username: 'developer', encrypted_password: 'weird_string' } }

      before do
        allow(described_class).to receive(:post).and_return({ 'user' => { 'email' => 'dev@boost.com', 'name' => 'dev', 'username' => 'developer', 'api_key' => '123456' } })
      end

      it 'executes a post request' do
        expect(described_class).to receive(:post).with('/users', {}, user: attributes)

        described_class.create(attributes)
      end

      it 'returns a Supplejack::User object with the api_key' do
        user = described_class.create(attributes)

        expect(user).to be_a described_class
        expect(user.api_key).to eq '123456'
      end
    end
  end
end
