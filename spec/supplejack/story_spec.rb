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
              "story" => {
                "id" => "new-id",
                "name" => attributes[:name],
                "description" => "",
                "tags" => [],
                "contents" => []
              }
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
          expect(Supplejack::Story).to receive(:patch).with("/stories/123", {api_key: "foobar"}, {story: attributes}) do
            {
              "story" => {
                "id" => "new-id",
                "name" => attributes[:name],
                "description" => "desc",
                "tags" => [],
                "contents" => []
              }
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
      after { story.update_attributes(name: 'Mac') }

      it 'sets the attributes on the Story' do
        expect(story).to receive('attributes=').with(name: 'Mac')
      end

      it 'saves the user_set' do
        expect(story).to receive(:save)
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


    # describe '#destroy' do
    #   before :each do
    #     supplejack_set.stub(:api_key) { '123abc' }
    #     supplejack_set.stub(:id) { '999' }
    #   end

    #   it 'executes a delete request to the API with the user set api_key' do
    #     Supplejack::UserSet.should_receive(:delete).with('/sets/999', {api_key: '123abc'})
    #     supplejack_set.destroy.should be_true
    #   end

    #   it 'returns false when the response is not a 200' do
    #     Supplejack::UserSet.stub(:delete).and_raise(RestClient::Forbidden.new)
    #     supplejack_set.destroy.should be_false
    #     supplejack_set.errors.should eq 'Forbidden: '
    #   end

    #   it 'returns false when it is a new user set' do
    #     supplejack_set.stub(:new_record?) { true }
    #     Supplejack::UserSet.should_not_receive(:delete)
    #     supplejack_set.destroy.should be_false
    #   end
    # end

    # describe '#reload' do
    #   let(:supplejack_set) { Supplejack::UserSet.new(id: '123456') }

    #   before :each do
    #     Supplejack::UserSet.should_receive(:get).with('/sets/123456') { {'set' => {'id' => 'abc'}} }
    #   end

    #   it 'fetches the set from the api and repopulates the set' do
    #     supplejack_set.reload
    #     supplejack_set.id.should eq 'abc'
    #   end

    #   it 'removes the existing @items relation' do
    #     supplejack_set.items
    #     supplejack_set.reload
    #     supplejack_set.instance_variable_get('@items').should be_nil
    #   end
    # end

    # describe '#viewable_by?' do
    #   it 'returns true when the user_set is public' do
    #     supplejack_set.stub(:public?) { true }
    #     supplejack_set.viewable_by?(nil).should be_true
    #   end

    #   it 'returns true when the user_set is hidden' do
    #     supplejack_set.stub(:hidden?) { true }
    #     supplejack_set.viewable_by?(nil).should be_true
    #   end

    #   context 'private set' do
    #     before :each do
    #       supplejack_set.stub(:public?) { false }
    #     end

    #     it 'returns false when the user is not present' do
    #       supplejack_set.viewable_by?(nil).should be_false
    #     end

    #     it 'returns true when the user has the same api_key as the user_set' do
    #       user = double(:user, api_key: '12345')
    #       supplejack_set.api_key = '12345'
    #       supplejack_set.viewable_by?(user).should be_true
    #     end

    #     it 'returns false if both the api_key in the user and the set are nil' do
    #       user = double(:user, api_key: nil)
    #       supplejack_set.api_key = nil
    #       supplejack_set.viewable_by?(user).should be_false
    #     end
    #   end
    # end

    # describe '#owned_by?' do
    #   let(:user) { double(:user, api_key: '123456') }

    #   it 'returns true when the users api_key is the same as the set\'s' do
    #     supplejack_set.stub(:api_key) { "123456" }
    #     supplejack_set.owned_by?(user).should be_true
    #   end

    #   it 'returns false when the set and user have different api_keys' do
    #     supplejack_set.stub(:api_key) { '666' }
    #     supplejack_set.owned_by?(user).should be_false
    #   end

    #   it 'returns false when both keys are nil' do
    #     user.stub(:api_key) { nil }
    #     supplejack_set.stub(:api_key) { nil }
    #     supplejack_set.owned_by?(user).should be_false
    #   end
    # end

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

    # describe '#find' do
    #   before :each do
    #     @set = supplejack_set
    #     Supplejack::UserSet.stub(:new) { @set }
    #   end

    #   it 'fetches the set from the api' do
    #     Supplejack::UserSet.should_receive(:get).with('/sets/123abc', {})
    #     Supplejack::UserSet.find('123abc')
    #   end

    #   it 'initializes a UserSet object' do
    #     Supplejack::UserSet.should_receive(:new).with({id: '123abc', name: 'Dogs', count: 0}).and_return(@set)
    #     set = Supplejack::UserSet.find('123abc')
    #     set.class.should eq Supplejack::UserSet
    #   end

    #   it 'initializes the UserSet and sets the user api_key' do
    #     set = Supplejack::UserSet.find('123abc', '98765')
    #     set.api_key.should eq '98765'
    #   end

    #   it 'raises a Supplejack::SetNotFound' do
    #     Supplejack::UserSet.stub(:get).and_raise(RestClient::ResourceNotFound)
    #     expect { Supplejack::UserSet.find('123') }.to raise_error(Supplejack::SetNotFound)
    #   end
    # end

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
