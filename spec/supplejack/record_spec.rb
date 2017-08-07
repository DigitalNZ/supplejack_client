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

class Search < Supplejack::Search
  def initialize(params={})
    super
    self.or = {:type => ['Person']}
  end
end

class SpecialSearch < Supplejack::Search
  def initialize(params={})
    super(params)
    if self.api_params && self.api_params[:and]
      self.api_params[:and].delete(:format)
    end
  end
end

module Supplejack
  describe Record do
    it 'initializes its attributes from a JSON string' do
      record = SupplejackRecord.new(%{{"type": "Person", "location": "NZ"}})
      record.attributes.should eq({:type => 'Person', :location => 'NZ'})
    end

    it 'handles nil params' do
      record = SupplejackRecord.new(nil)
      record.attributes.should eq({})
    end

    it 'handles a string as params' do
      record = SupplejackRecord.new('')
      record.attributes.should eq({})
    end

    it 'handles a array as params' do
      record = SupplejackRecord.new([])
      record.attributes.should eq({})
    end

    it 'raises a NoMethodError for every method call that doesn\'t have a key in the attributes' do
      record = SupplejackRecord.new
      expect { record.something }.to raise_error(NoMethodError)
    end

    it 'should return the value when is present in the attributes' do
      record = SupplejackRecord.new(:weird_method => 'Something')
      record.weird_method.should eq 'Something'
    end

    describe 'id' do
      it 'returns the record_id' do
        record = SupplejackRecord.new({'record_id' => '95'})
        record.id.should eq 95
      end

      it 'returns the id' do
        record = SupplejackRecord.new({'id' => '96'})
        record.id.should eq 96
      end
    end

    describe '#title' do
      it 'returns the title attribute value' do
        SupplejackRecord.new(title: 'Dogs').title.should eq 'Dogs'
      end

      it 'returns "Untitled" for records without a title' do
        SupplejackRecord.new(title: nil).title.should eq 'Untitled'
      end
    end

    describe '#metadata' do
      it 'returns an array of hashes with special fields their values and schemas' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:location]}} }
        record = SupplejackRecord.new({:location => 'Wellington'})
        record.metadata.should include({:name => 'location', :schema => 'admin', :value => 'Wellington'})
      end

      it 'returns an array of hashes with special fields their values and schemas for multiple special_fields configured' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:location]}, user: {fields: [:description]}} }
        record = SupplejackRecord.new({:location => 'Wellington', :description => "Some description"})
        record.metadata.should include({:name => 'location', :schema => 'admin', :value => 'Wellington'}, {:name => 'description', :schema => 'user', :value => 'Some description'})
      end

      it 'should not return metadata for inexistent attribtues' do
        Supplejack.stub(:supplejack_fields) { [:description] }
        record = SupplejackRecord.new({:location => 'Wellington'})
        record.metadata.should be_empty
      end

      it 'returns multiple elements for a multi value field' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:location]}} }
        record = SupplejackRecord.new({:location => ['Wellington', 'Auckland']})
        record.metadata.should include({:name => 'location', :schema => 'admin', :value => 'Wellington'}, {:name => 'location', :schema => 'admin', :value => 'Auckland'})
      end

      it 'returns a empty array for a empty field' do
        Supplejack.stub(:supplejack_fields) { [:location] }
        record = SupplejackRecord.new({:location => nil})
        record.metadata.should be_empty
      end

      it 'works for boolean fields too' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:is_human]}} }
        record = SupplejackRecord.new({:is_human => true})
        record.metadata.should include({:name => 'is_human', :schema => 'admin', :value => true})
      end

      # it 'works for boolean fields when they are true' do
      #   Supplejack.stub(:admin_fields) { [:is_animal] }
      #   record = SupplejackRecord.new({:is_animal => true})
      #   record.metadata.should include({:name => 'is_animal', :schema => 'admin', :value => true})
      # end

      it 'works for boolean fields when they are false' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:is_human]}} }
        record = SupplejackRecord.new({:is_human => false})
        record.metadata.should include({:name => 'is_human', :schema => 'admin', :value => false})
      end

      it 'returns names with the schema removed' do
        Supplejack.stub(:special_fields) { {admin: {fields: [:admin_identifier]}} }
        record = SupplejackRecord.new({:admin_identifier => 'sj:IE1174615'})
        record.metadata.should include({:name => 'identifier', :schema => 'admin', :value => 'sj:IE1174615'})
      end
    end

    describe '#single_value_methods' do
      before(:each) do
        Supplejack.single_value_methods = [:description]
      end

      it 'converts values defined in the single_value_methods to a string' do
        record = SupplejackRecord.new({'description' => ['One', 'Two']})
        record.description.should eq 'One'
      end

      it 'returns the string if is already a string' do
        record = SupplejackRecord.new({'description' => 'One'})
        record.description.should eq 'One'
      end
    end

    [:next_record, :previous_record, :next_page, :previous_page].each do |attr|
      describe "#{attr}" do
        it "returns the #{attr}" do
          record = SupplejackRecord.new({attr => 1})
          record.send(attr).should eq 1
        end

        it "returns the nil" do
          record = SupplejackRecord.new({})
          record.send(attr).should be_nil
        end
      end
    end

    describe '#find' do
      context 'single record' do
        it 'raises a Supplejack::RecordNotFound' do
          SupplejackRecord.stub(:get).and_raise(RestClient::ResourceNotFound)
          expect { SupplejackRecord.find(1) }.to raise_error(Supplejack::RecordNotFound)
        end

        it 'raises a Supplejack::MalformedRequest' do
          expect { SupplejackRecord.find('replace_this') }.to raise_error(Supplejack::MalformedRequest)
        end

        it 'requests the record from the API' do
          SupplejackRecord.should_receive(:get).with('/records/1', {:fields => 'default'}).and_return({'record' => {}})
          SupplejackRecord.find(1)
        end

        it 'initializes a new SupplejackRecord object' do
          SupplejackRecord.stub(:get).and_return({'record' => {'record_id' => '1', 'title' => 'Wellington'}})
          record = SupplejackRecord.find(1)
          record.class.should eq SupplejackRecord
          record.id.should eq 1
          record.title.should eq 'Wellington'
        end

        it 'send the fields defined in the configuration' do
          Supplejack.stub(:fields) { [:verbose,:default] }
          SupplejackRecord.should_receive(:get).with('/records/1', {:fields => 'verbose,default'}).and_return({'record' => {}})
          SupplejackRecord.find(1)
        end

        it 'sets the correct search options' do
          SupplejackRecord.should_receive(:get).with('/records/1', hash_including(:search => hash_including({:text=>'dog'}))).and_return({'record' => {}})
          SupplejackRecord.find(1, {:text => 'dog'})
        end

        context '#using a special search klass' do
          before(:each) do
            @search = ::Search.new
          end

          it 'uses the specified search klass' do
            SupplejackRecord.stub(:get) { {'record' => {}} }
            Supplejack.stub(:search_klass) { 'Search' }
            ::Search.should_receive(:new).with({:i => {:location => 'Wellington'}}).and_return(@search)
            SupplejackRecord.find(1, {:i => {:location => 'Wellington'}})
          end

          it 'uses the default search klass' do
            SupplejackRecord.stub(:get) { {'record' => {}} }
            Supplejack.stub(:search_klass) { nil }
            Supplejack::Search.should_receive(:new).with({:i => {:location => 'Wellington'}}).and_return(@search)
            SupplejackRecord.find(1, {:i => {:location => 'Wellington'}})
          end

          it 'sends the params from the subclassed search to the API' do
            Supplejack.stub(:search_klass) { 'Search' }
            SupplejackRecord.should_receive(:get).with("/records/1", hash_including(:search => hash_including(:and=>{:name=>'John'}, :or=>{:type=>['Person']}))).and_return({'record' => {}})
            SupplejackRecord.find(1, {:i => {:name => 'John'}})
          end

          it 'sends any changes to the api_params made on the subclassed search object' do
            Supplejack.stub(:search_klass) { 'SpecialSearch' }
            SupplejackRecord.should_receive(:get).with('/records/1', hash_including(:search => hash_including(:and=>{}))).and_return({'record' => {}})
            SupplejackRecord.find(1, {:i => {:format => 'Images'}})
          end
        end
      end

      context 'multiple records' do
        it 'sends a request to /records/multiple endpoint with an array of record ids' do
          SupplejackRecord.should_receive(:get).with('/records/multiple', {:record_ids => [1,2], :fields => 'default'}).and_return({'records' => []})
          SupplejackRecord.find([1,2])
        end

        it 'initializes multiple SupplejackRecord objects' do
          SupplejackRecord.stub(:get).and_return({'records' => [{'id' => '1'}, {'id' => '2'}]})
          records = SupplejackRecord.find([1,2])
          records.size.should eq 2
          records.first.class.should eq SupplejackRecord
          records.first.id.should eq 1
        end

        it 'requests the fields in Supplejack.fields' do
          Supplejack.stub(:fields) { [:verbose,:description] }
          SupplejackRecord.should_receive(:get).with('/records/multiple', {:record_ids => [1,2], :fields => 'verbose,description'}).and_return({'records' => []})
          SupplejackRecord.find([1,2])
        end
      end
    end

  end
end
