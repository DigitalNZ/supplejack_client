# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

module Supplejack
  describe Story do
    let(:supplejack_set) { Supplejack::UserSet.new(records: [{record_id: 1, position: 2, title: 'Dogs'}]) }

    before do
      Supplejack.stub(:enable_caching) { false }
    end

    describe '#initialize' do
      Supplejack::Story::ATTRIBUTES.reject{|a| a =~ /_at/}.each do |attribute|
        it "initializes the #{attribute}" do
          expect(Supplejack::Story.new({attribute => 'value'}).send(attribute)).to eq 'value'
        end
      end


      it 'handles nil attributes' do
        expect{Supplejack::Story.new(nil).attributes}.not_to raise_error
      end

      it 'initializes a user object' do
        story = Supplejack::Story.new({user: {name: 'Juanito'}})
        expect(story.user).to be_a Supplejack::User
        expect(story.user.name).to eq 'Juanito'
      end
    end

    [:updated_at, :created_at].each do |field|
      describe "##{field}" do
        let(:story) {Supplejack::Story.new(field => '2012-08-17T10:01:00+12:00')}

        it "converts it into a time object" do
          expect(story.send(field)).to be_a Time
        end

        it 'sets it to nil when the time is incorrect' do
          story.send("#{field}=", '838927587hdfhsjdf')

          expect(story.send(field)).to be_nil
        end

        it 'accepts a Time object too' do
          time = Time.now

          story.send("#{field}=", time)

          expect(story.send(field)).to eq time
        end
      end
    end

    describe '#attributes' do
      it 'returns a hash of the set attributes' do
        story = Supplejack::Story.new

        story.name = 'Dogs'
        story.description = 'Hi'

        expect(story.attributes).to include(name: 'Dogs', description: 'Hi')
      end

      # it 'includes an array of :records' do
      #   set = Supplejack::UserSet.new
      #   set.records = [{record_id: 1, position: 1}]
      #   set.attributes[:records].should eq [{record_id: 1, position: 1}]
      # end
    end

    describe '#api_attributes' do
      it 'only returns the fields that can be modified' do
        story = Supplejack::Story.new(name: 'foo', id: 'bar')

        attributes = story.api_attributes

        expect(attributes).to include(:name)
        expect(attributes).not_to include(:id)
      end
    end

    # describe '#items' do
    #   it "initializes a item_relation object" do
    #     supplejack_set.items.should be_a Supplejack::ItemRelation
    #   end
    # end

    describe '#tag_list' do
      it 'returns a comma sepparated list of tags' do
        expect(Supplejack::Story.new(tags: ['dog', 'cat']).tag_list).to eq 'dog, cat'
      end
    end

    describe '#private?' do
      it 'returns true when the privacy is private' do
        expect(Supplejack::Story.new(privacy: 'private').private?).to eq true
      end

      it 'returns false when the privacy is something else' do
        expect(Supplejack::Story.new(privacy: 'public').private?).to eq false
      end
    end

    describe '#public?' do
      it 'returns false when the privacy is private' do
        expect(Supplejack::Story.new(privacy: 'private').public?).to eq false
      end

      it 'returns true when the privacy is public' do
        expect(Supplejack::Story.new(privacy: 'public').public?).to eq true
      end
    end

    describe '#hidden?' do
      it 'returns false when the privacy is not hidden' do
        expect(Supplejack::Story.new(privacy: 'public').hidden?).to eq false
      end

      it 'returns true when the privacy is hidden' do
        expect(Supplejack::Story.new(privacy: 'hidden').hidden?).to eq true
      end
    end

    describe '#new_record?' do
      it "returns true when the user_set doesn't have a id" do
        expect(Supplejack::Story.new.new_record?).to eq true
      end

      it 'returns false when the user_set has a id' do
        expect(Supplejack::Story.new(id: '1234abc').new_record?).to eq false
      end
    end

    describe '#api_key' do
      it 'returns the users api_key' do
        expect(Supplejack::Story.new(user: {api_key: 'foobar'}).api_key).to eq 'foobar'
      end
    end

    describe '#save' do
      context 'Story is a new_record' do
        let(:attributes) {{name: 'Story Name'}}
        let(:user) {{api_key: 'foobar'}}
        let(:story) {Supplejack::Story.new(attributes.merge(user: user))}

        before do
          expect(Supplejack::Story).to receive(:post).with("/stories", {api_key: "foobar"}, {story: attributes}) do
            {
              "id" => "new-id",
              "name" => attributes[:name],
              "description" => "",
              "tags" => [],
              "contents" => []
            }
          end
        end

        it 'triggers a POST request to /stories.json' do
          expect(story.save).to eq true
        end

        it 'stores the id of the user_set' do
          story.save

          expect(story.id).to eq 'new-id'
        end

        it 'updates the attributes with the response' do
          story.save

          expect(story.tags).to eq []
        end

        it 'returns false for anything other that a 200 response' do
          RSpec::Mocks.proxy_for(Supplejack::Story).reset
          Supplejack::Story.stub(:post).and_raise(RestClient::Forbidden.new)

          expect(story.save).to eq false
        end
      end

      context 'user_set is not new' do
        let(:attributes) {{name: 'Story Name', description: 'desc'}}
        let(:user) {{api_key: 'foobar'}}
        let(:story) {Supplejack::Story.new(attributes.merge(user: user, id: '123'))}

        before do
          expect(Supplejack::Story).to receive(:patch).with("/stories/123", payload: {story: attributes}) do
            {
              "id" => "new-id",
              "name" => attributes[:name],
              "description" => "desc",
              "tags" => [],
              "contents" => []
            }
          end
        end

        it 'triggers a PATCH request to /stories/123.json with the user set api_key' do
          story.save
        end

        it 'updates the attributes with the response' do
          story.save

          expect(story.description).to eq 'desc'
        end
      end
    end

    describe '#update_attributes' do
      let(:story) {Supplejack::Story.new(name: 'test', description: 'test')}

      it 'sets the attributes on the Story' do
        story.update_attributes(name: 'Mac')

        expect(story.name).to eq('Mac')
      end

      it 'saves the user_set' do
        expect(story).to receive(:save)

        story.update_attributes(name: 'Mac')
      end
    end

    describe '#attributes=' do
      let(:story) {Supplejack::Story.new(name: 'Foo')}

      it 'updates the attributes on the story' do
        story.attributes = {name: 'Mac'}

        expect(story.name).to eq 'Mac'
      end

      it 'should only update passed attributes' do
        story.id = '12345'
        story.attributes = {name: 'Mac'}

        expect(story.id).to eq '12345'
      end
    end

    # describe '#api_records' do
    #   it 'generates a hash of records with position and record_id' do
    #     supplejack_set.stub(:records) { [{title: 'Hi', record_id: 1, position: 1} ] }
    #     supplejack_set.api_records.should eq [{record_id: 1, position: 1}]
    #   end

    #   it 'removes records without a record_id' do
    #     supplejack_set.stub(:records) { [{title: 'Hi', record_id: 1, position: 1}, {position: 6} ] }
    #     supplejack_set.api_records.should eq [{record_id: 1, position: 1}]
    #   end

    #   it 'handles nil records' do
    #     supplejack_set.stub(:records) { nil }
    #     supplejack_set.api_records.should eq []
    #   end
    # end

    # describe '#ordered_records_from_array' do
    #   it 'returns a hash with positons and record_ids' do
    #     supplejack_set.ordered_records_from_array([9,1,5]).should eq([{record_id: 9, position: 1}, {record_id: 1, position: 2}, {record_id: 5, position: 3}])
    #   end
    # end


    describe '#destroy' do
      let(:story) {Supplejack::Story.new(id: '999')}

      it 'executes a delete request to the API with the user set api_key' do
        expect(Supplejack::Story).to receive(:delete).with('/stories/999')

        expect(story.destroy).to eq(true)
      end

      it 'returns false when the response is not a 200' do
        expect(Supplejack::Story).to receive(:delete).and_raise(RestClient::Forbidden.new)

        expect(story.destroy).to eq(false)
        expect(story.errors).to eq('Forbidden: ')
      end

      it 'returns false when it is a new user set' do
        expect(story).to receive(:new_record?) { true }
        expect(Supplejack::Story).not_to receive(:delete)

        expect(story.destroy).to eq(false)
      end
    end

    describe '#reload' do
      let(:story) { Supplejack::Story.new(id: '123456') }

      it 'fetches the set from the api and repopulates the set' do
        expect(Supplejack::Story).to receive(:get).with('/stories/123456') { {'id' => 'abc'} }

        story.reload

        expect(story.id).to eq('abc')
      end

      it 'raises Supplejack::StoryNotFound if the Story is not found' do
        expect(Supplejack::Story).to receive(:get).and_raise(RestClient::ResourceNotFound.new)

        expect{story.reload}.to raise_error(Supplejack::StoryNotFound)
      end

      # it 'removes the existing @items relation' do
      #   supplejack_set.items
      #   supplejack_set.reload
      #   supplejack_set.instance_variable_get('@items').should be_nil
      # end
    end

    describe '#viewable_by?' do
      let(:api_key) { '123' }
      let(:user) { { api_key: api_key } }

      it 'returns true when the Story is public' do
        story = Supplejack::Story.new(privacy: 'public')

        expect(story.viewable_by?(nil)).to eq(true)
      end

      it 'returns true when the user_set is hidden' do
        story = Supplejack::Story.new(privacy: 'hidden')

        expect(story.viewable_by?(nil)).to eq(true)
      end

      context 'private set' do
        let(:story) { Supplejack::Story.new(privacy: 'private', user: user) }

        it 'returns false when the user is not present' do
          expect(story.viewable_by?(nil)).to eq(false)
        end

        it 'returns true when the user has the same api_key as the user_set' do
          expect(story.viewable_by?(Supplejack::User.new(user))).to eq(true)
        end

        it 'returns false if both the api_key in the user and the set are nil' do
          user = { api_key: nil }
          story = Supplejack::Story.new(privacy: 'private', user: user)

          expect(story.viewable_by?(Supplejack::User.new(user))).to eq(false)
        end
      end
    end

    describe '#owned_by?' do
      let(:api_key) { '123456' }
      let(:user) { Supplejack::User.new(api_key: api_key) }
      let(:users_story) { Supplejack::Story.new(user: { api_key: api_key }) }
      let(:other_story) { Supplejack::Story.new(user: { api_key: '123' }) }
      let(:nil_api_key_story) { Supplejack::Story.new(user: { api_key: nil }) }

      it "returns true when the users api_key is the same as the set's" do
        expect(users_story.owned_by? user).to eq(true)
      end

      it 'returns false when the set and user have different api_keys' do
        expect(other_story.owned_by? user).to eq(false)
      end

      it 'returns false when both keys are nil' do
        expect(nil_api_key_story.owned_by? user).to eq(false)
      end
    end

    # describe '#set_record_id?' do
    #   before(:each) do
    #     @set = supplejack_set
    #   end

    #   it 'should return the record_id' do
    #     @set.stub(:record).and_return({'record_id' => 123})
    #     @set.set_record_id.should eq 123
    #   end

    #   it 'should return nil if the set doesn\'t have a record' do
    #     @set.set_record_id.should be_nil
    #   end
    # end

    describe '#find' do
      let(:attributes) do
        {
          "name" => "foo",
          "description" => "desc"
        }
      end

      it 'fetches the Story from the API' do
        Supplejack::Story.should_receive(:get).with('/stories/123abc', {}).and_return(attributes)

        Supplejack::Story.find('123abc')
      end

      it 'initializes a Story object' do
        Supplejack::Story.should_receive(:get).with('/stories/123abc', {}).and_return(attributes)

        story = Supplejack::Story.find('123abc')

        expect(story.attributes).to eq(attributes.symbolize_keys)
      end

      # I've removed this functionality because I don't understand the use case
      # If we _do_ end up needing it in the future we can re add it
      # it 'initializes the Story and sets the user api_key' do
      #   Supplejack::Story.should_receive(:get).with('/stories/123abc', {api_key: '98765'}).and_return(attributes)

      #   story = Supplejack::Story.find(id: '123abc', api_key: '98765')

      #   expect(story.api_key).to eq('98765')
      # end

      it 'raises a Supplejack::StoryNotFound' do
        Supplejack::Story.stub(:get).and_raise(RestClient::ResourceNotFound)

        expect { Supplejack::Story.find(id: '123') }.to raise_error(Supplejack::StoryNotFound)
      end
    end

    # describe '#public_sets' do
    #   before :each do
    #     Supplejack::UserSet.stub(:get) { {'sets' => [{'id' => '123', 'name' => 'Dog'}]} }
    #   end

    #   it 'fetches the public sets from the api' do
    #     Supplejack::UserSet.should_receive(:get).with('/sets/public', {page: 1, per_page: 100})
    #     Supplejack::UserSet.public_sets
    #   end

    #   it 'returns an array of user set objects' do
    #     @set = supplejack_set
    #     Supplejack::UserSet.should_receive(:new).once.with({'id' => '123', 'name' => 'Dog'}) { @set }
    #     sets = Supplejack::UserSet.public_sets
    #     sets.should be_a Array
    #     sets.size.should eq 1
    #   end

    #   it 'sends pagination information' do
    #     Supplejack::UserSet.should_receive(:get).with('/sets/public', {page: 2, per_page: 100})
    #     Supplejack::UserSet.public_sets(page: 2)
    #   end
    # end

    # describe '#featured_sets' do
    #   before :each do
    #     Supplejack::UserSet.stub(:get) { {'sets' => [{'id' => '123', 'name' => 'Dog'}]} }
    #   end

    #   it 'fetches the public sets from the api' do
    #     Supplejack::UserSet.should_receive(:get).with('/sets/featured')
    #     Supplejack::UserSet.featured_sets
    #   end

    #   it 'returns an array of user set objects' do
    #     @set = supplejack_set
    #     Supplejack::UserSet.should_receive(:new).once.with({'id' => '123', 'name' => 'Dog'}) { @set }
    #     sets = Supplejack::UserSet.featured_sets
    #     sets.should be_a Array
    #     sets.size.should eq 1
    #   end
    # end
  end
end
