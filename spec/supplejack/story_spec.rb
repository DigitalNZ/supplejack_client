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

      [:updated_at, :created_at].each do |field|
        it "converts the #{field} into a time object" do
          story = Supplejack::Story.new(field => '2012-08-17T10:01:00+12:00')
          expect(story.send(field)).to be_a Time
        end
      end

      # it 'symbolizes the attributes hash' do
      #   Supplejack::UserSet.new({'name' => 'Dog'}).name.should eq 'Dog'
      # end

      # it 'handles nil attributes' do
      #   Supplejack::UserSet.new(nil).attributes
      # end

      # it 'initializes a user object' do
      #   user_set = Supplejack::UserSet.new({user: {name: 'Juanito'}})
      #   user_set.user.should be_a Supplejack::User
      #   user_set.user.name.should eq 'Juanito'
      # end
    end

    # describe '#attributes' do
    #   it 'returns a hash of the set attributes' do
    #     set = Supplejack::UserSet.new
    #     set.name = 'Dogs'
    #     set.description = 'Hi'
    #     set.attributes.should include(name: 'Dogs', description: 'Hi')
    #   end

    #   it 'includes an array of :records' do
    #     set = Supplejack::UserSet.new
    #     set.records = [{record_id: 1, position: 1}]
    #     set.attributes[:records].should eq [{record_id: 1, position: 1}]
    #   end
    # end

    # describe '#api_attributes' do
    #   it 'only returns the fields that can be stored' do
    #     supplejack_set.attributes = {count: 1, url: 'Hi'}
    #     supplejack_set.should_not_receive(:count)
    #     supplejack_set.should_not_receive(:url)
    #     supplejack_set.api_attributes
    #   end

    #   it 'should send the featured value' do
    #     supplejack_set.featured = true
    #     supplejack_set.api_attributes.should include(featured: true)
    #   end

    #   it 'returns a array of records with only id and position' do
    #     supplejack_set.stub(:api_records) { [{record_id: 1, position: 1}] }
    #     supplejack_set.api_attributes[:records].should eq [{record_id: 1, position: 1}]
    #   end
    # end

    # describe '#items' do
    #   it "initializes a item_relation object" do
    #     supplejack_set.items.should be_a Supplejack::ItemRelation
    #   end
    # end

    # describe '#tag_list' do
    #   it 'returns a comma sepparated list of tags' do
    #     Supplejack::UserSet.new(tags: ['dog', 'cat']).tag_list.should eq 'dog, cat'
    #   end
    # end

    # describe '#priority' do
    #   it 'defaults to 1 when is null' do
    #     Supplejack::UserSet.new.priority.should eq 1
    #   end

    #   it 'keeps the value set' do
    #     Supplejack::UserSet.new(priority: 0).priority.should eq 0
    #   end
    # end

    # describe '#favourite?' do
    #   it 'returns true when the name is Favourites' do
    #     Supplejack::UserSet.new(name: 'Favourites').favourite?.should be_true
    #   end

    #   it 'returns false when the name is something else' do
    #     Supplejack::UserSet.new(name: 'Dogs').favourite?.should be_false
    #   end
    # end

    # describe '#private?' do
    #   it 'returns true when the privacy is private' do
    #     Supplejack::UserSet.new(privacy: 'private').private?.should be_true
    #   end

    #   it 'returns false when the privacy is something else' do
    #     Supplejack::UserSet.new(privacy: 'public').private?.should be_false
    #   end
    # end

    # describe '#public?' do
    #   it 'returns false when the privacy is private' do
    #     Supplejack::UserSet.new(privacy: 'private').public?.should be_false
    #   end

    #   it 'returns true when the privacy is public' do
    #     Supplejack::UserSet.new(privacy: 'public').public?.should be_true
    #   end
    # end

    # describe '#hidden?' do
    #   it 'returns false when the privacy is not hidden' do
    #     Supplejack::UserSet.new(privacy: 'public').hidden?.should be_false
    #   end

    #   it 'returns true when the privacy is hidden' do
    #     Supplejack::UserSet.new(privacy: 'hidden').hidden?.should be_true
    #   end
    # end

    # describe '#has_record?' do
    #   let(:supplejack_set) { Supplejack::UserSet.new(records: [{record_id: 1, position: 2, title: 'Dogs'}]) }

    #   it 'returns true when the record is part of the set' do
    #     supplejack_set.has_record?(1).should be_true
    #   end

    #   it 'returns false when the record is not part of the set' do
    #     supplejack_set.has_record?(3).should be_false
    #   end
    # end

    # describe '#save' do
    #   before :each do
    #     @attributes = {name: 'Dogs', description: 'hi', count: 3}
    #     supplejack_set.stub(:api_attributes) { @attributes }
    #     supplejack_set.stub(:api_key) { '123abc' }
    #   end

    #   context 'user_set is a new_record' do
    #     before :each do
    #       supplejack_set.stub(:new_record?) { true }
    #     end

    #     it 'triggers a POST request to /sets.json' do
    #       Supplejack::UserSet.should_receive(:post).with("/sets", {api_key: "123abc"}, {set: @attributes}) { {"set" => {"id" => "new-id"}} }
    #       supplejack_set.save.should be_true
    #     end

    #     it 'stores the id of the user_set' do
    #       Supplejack::UserSet.stub(:post) { {'set' => {'id' => 'new-id'}} }
    #       supplejack_set.save
    #       supplejack_set.id.should eq 'new-id'
    #     end

    #     it 'returns false for anything other that a 200 response' do
    #       Supplejack::UserSet.stub(:post).and_raise(RestClient::Forbidden.new)
    #       supplejack_set.save.should be_false
    #     end
    #   end

    #   context 'user_set is not new' do
    #     before :each do
    #       supplejack_set.stub(:new_record?) { false }
    #       supplejack_set.id = '123'
    #     end

    #     it 'triggers a PUT request to /sets/123.json with the user set api_key' do
    #       Supplejack::UserSet.should_receive(:put).with('/sets/123', {api_key: '123abc'}, {set: @attributes})
    #       supplejack_set.save
    #     end
    #   end
    # end

    # describe '#update_attributes' do
    #   it 'sets the attributes on the user_set' do
    #     supplejack_set.should_receive('attributes=').with(name: 'Mac')
    #     supplejack_set.update_attributes({name: 'Mac'})
    #   end

    #   it 'saves the user_set' do
    #     supplejack_set.should_receive(:save)
    #     supplejack_set.update_attributes({name: 'Mac'})
    #   end
    # end

    # describe '#attributes=' do
    #   it 'updates the attributes on the user_set' do
    #     supplejack_set.attributes = {name: 'Mac'}
    #     supplejack_set.name.should eq 'Mac'
    #   end

    #   it 'should only update passed attributes' do
    #     supplejack_set.id = '12345'
    #     supplejack_set.attributes = {name: 'Mac'}
    #     supplejack_set.id.should eq '12345'
    #   end

    #   it "replaces the records in the ordered form" do
    #     supplejack_set.attributes = {ordered_records: [9,1,5]}
    #     supplejack_set.records.should eq([{record_id: 9, position: 1}, {record_id: 1, position: 2}, {record_id: 5, position: 3}])
    #   end
    # end

    # describe '#updated_at= and created_at=' do
    #   [:created_at, :updated_at].each do |attr|
    #     it 'converts a string into a time object' do
    #       supplejack_set.send("#{attr}=", '2012-08-17T10:01:00+12:00')
    #       supplejack_set.send(attr).should be_a Time
    #     end

    #     it 'sets nil when the time is incorrect' do
    #       supplejack_set.send("#{attr}=", '838927587hdfhsjdf')
    #       supplejack_set.send(attr).should be_nil
    #     end

    #     it 'should accept a Time object too' do
    #       @time = Time.now
    #       supplejack_set.send("#{attr}=", @time)
    #       supplejack_set.send(attr).should eq @time
    #     end
    #   end
    # end

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

    # describe '#new_record?' do
    #   it 'returns true when the user_set doesn\'t have a id' do
    #     Supplejack::UserSet.new.new_record?.should be_true
    #   end

    #   it 'returns false when the user_set has a id' do
    #     Supplejack::UserSet.new(id: '1234abc').new_record?.should be_false
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
