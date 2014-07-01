# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe User do
    let(:user) { Supplejack::User.new({'id' => 'abc', 'authentication_token' => '12345'}) }

    before(:each) do
      Supplejack::User.stub(:get) { {'user' => {'id' => 'abc', 'authentication_token' => '12345'}} }
    end
    
    describe '#initialize' do
      it 'initializes the user attributes' do
        Supplejack::User.new({'authentication_token' => '12345'}).api_key.should eq '12345'
      end

      it 'initializes the user name' do
        Supplejack::User.new({'name' => 'Juanito'}).name.should eq 'Juanito'
      end

      it 'initializes the sets attributes' do
        Supplejack::User.new({'sets' => [{name: 'Dogs'}]}).sets_attributes.should eq [{name: 'Dogs'}]
      end

      it 'initializes the use_own_api attribute' do
        Supplejack::User.new({'use_own_api_key' => true}).use_own_api_key.should be_true
      end

      it 'initializes the regenerate_api_key attribute' do
        Supplejack::User.new({'regenerate_api_key' => true}).regenerate_api_key.should be_true
      end
    end

    describe '#save' do
      it 'should execute a put request with the user attribtues' do
        user.stub(:api_attributes) { {username: 'John', email: 'john@boost.co.nz'} }
        Supplejack::User.should_receive(:put).with('/users/12345', {}, {username: 'John', email: 'john@boost.co.nz'})
        user.save.should be_true
      end

      context 'regenerate api key' do
        before(:each) do
          user.regenerate_api_key = true
        end

        it 'should post a nil authentication_token attribute so it is regenerated' do
          Supplejack::User.should_receive(:put).with('/users/12345', {}, hash_including(authentication_token: nil))
          user.save
        end

        it 'should set the regenerated api_key on the user' do
          Supplejack::User.stub(:put).and_return({'user'=>{'id'=>'525f7a2df6941993e2000004', 'name'=>nil, 'username'=>nil, 'email'=>nil, 'api_key'=>'71H5yPsxVhDmsjmj1NJW'}})
          user.save
          user.instance_variable_get('@api_key').should eq '71H5yPsxVhDmsjmj1NJW'
        end

      end

      it 'returns false when a error ocurred' do
        Supplejack::User.stub(:put).and_raise(RestClient::Forbidden)
        user.save.should be_false
      end
    end

    describe '#destroy' do
      it 'should execute a delete request with the admin key' do
        Supplejack.stub(:api_key) { 'admin_key' }
        Supplejack::User.should_receive(:delete).with('/users/abc')
        user.destroy.should be_true
      end

      it 'returns false if there is a exception' do
        Supplejack::User.stub(:delete).and_raise(RestClient::Forbidden)
        user.destroy.should be_false
      end
    end

    describe '#api_attributes' do
      it 'returns the name, username, email and encrypted_password' do
        user = Supplejack::User.new(name: 'John', username: 'Johnny', email: 'john@boost.co.nz', encrypted_password: 'xyz', api_key: '12345')
        user.api_attributes.should eq({name: 'John', username: 'Johnny', email: 'john@boost.co.nz', encrypted_password: 'xyz'})
      end

      it 'doesn\'t return the attribute if not present' do
        user.api_attributes.should_not include(:name)
      end

      context 'regenerate api key' do
        let(:user) { Supplejack::User.new(api_key: '12345', regenerate_api_key: true) }

        it 'returns a nil authentication_token' do
          user.api_attributes.should have_key(:authentication_token)
          user.api_attributes[:authentication_token].should be_nil
        end
      end

      it 'returns the sets_attributes' do
        user = Supplejack::User.new(sets: [{name: 'Dogs', privacy: 'hidden'}])
        user.api_attributes[:sets].should eq [{name: 'Dogs', privacy: 'hidden'}]
      end
    end

    describe '#use_own_api_key?' do
      it 'returns false by default' do
        Supplejack::User.new.use_own_api_key?.should be_false
      end

      it 'returns true' do
        Supplejack::User.new('use_own_api_key' => true).use_own_api_key?.should be_true
      end
    end

    describe '#regenerate_api_key?' do
      it 'returns false by default' do
        Supplejack::User.new.regenerate_api_key?.should be_false
      end

      it 'returns true' do
        Supplejack::User.new('regenerate_api_key' => true).regenerate_api_key?.should be_true
      end
    end

    describe '.find' do
      it 'fetches the user from the api' do
        Supplejack::User.should_receive(:get).with('/users/12345')
        Supplejack::User.find('12345')
      end

      it 'initializes a user with the response' do
        Supplejack::User.should_receive(:new).with({'id' => 'abc', 'authentication_token' => '12345'})
        Supplejack::User.find('12345')
      end
    end

    describe '.create' do
      before :each do
        @attributes = {email: 'dev@boost.com', name: 'dev', username: 'developer', encrypted_password: 'weird_string'}
        Supplejack::User.stub(:post) { {'user' => {'email' => 'dev@boost.com', 'name' => 'dev', 'username' => 'developer', 'api_key' => '123456'}} }
      end

      it 'executes a post request' do
        Supplejack::User.should_receive(:post).with("/users", {}, {user: @attributes})
        Supplejack::User.create(@attributes)
      end

      it 'returns a Supplejack::User object with the api_key' do
        user = Supplejack::User.create(@attributes)
        user.should be_a Supplejack::User
        user.api_key.should eq '123456'
      end
    end
  end
end
