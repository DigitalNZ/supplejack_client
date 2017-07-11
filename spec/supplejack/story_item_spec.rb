# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
	describe StoryItem do

    describe '#initialize' do
      it 'accepts a hash of attributes' do
        Supplejack::StoryItem.new(type: 'embed', sub_type: 'record')
      end

      it 'accepts a hash with string keys' do
        expect(Supplejack::StoryItem.new({'type' => 'embed', 'sub_type' => 'record'}).type).to eq('embed')
      end

      it 'handles nil attributes' do
        expect(Supplejack::StoryItem.new(nil).type).to be_nil
      end

      Supplejack::StoryItem::ATTRIBUTES.each do |attribute|
        it "should initialize the attribute #{attribute}" do
          Supplejack::StoryItem.new({attribute => 'value'}).send(attribute).should eq 'value'
        end
      end
    end

    describe '#save' do
      let(:item) { Supplejack::StoryItem.new(type: 'embed', sub_type: 'record', story_id: '1234', api_key: 'abc') }

      context 'new item' do
        it 'triggers a POST request to create a story_item with the story api_key' do
          expect(item).to receive(:post).with('/stories/1234/items', {user_key: 'abc'}, {item: {meta: {}, type: 'embed', sub_type: 'record'}})

          expect(item.save).to eq(true)
        end
      end

      context 'existing item' do
        it 'triggers a PATCH request to update a story_item with the story api_key' do
          item.id = 1
          expect(item).to receive(:patch).with('/stories/1234/items/1', {user_key: 'abc'}, {item: {meta: {}, type: 'embed', sub_type: 'record'}})

          expect(item.save).to eq(true)
        end
      end

      context 'HTTP error is raised' do
        before do
          item.stub(:post).and_raise(RestClient::Forbidden.new)
        end

        it 'returns false when an HTTP error is raised' do
          expect(item.save).to eq(false)
        end

        it 'stores the error when a error is raised' do
          item.save

          expect(item.errors).to eq 'Forbidden'
        end
      end
    end

    describe '#destroy' do
      let(:item) { Supplejack::StoryItem.new(story_id: '1234', api_key: 'abc', id: 5) }

      it 'triggers a DELETE request with the story api_key' do
        expect(item).to receive(:delete).with('/stories/1234/items/5', {user_key: 'abc'})

        item.destroy
      end

      context 'HTTP error is raised' do
        before do
          item.stub(:delete).and_raise(RestClient::Forbidden.new)
        end

        it 'returns false when a HTTP error is raised' do
          expect(item.destroy).to eq(false)
        end

        it 'stores the error when a error is raised' do
          item.destroy

          expect(item.errors).to eq 'Forbidden'
        end
      end
    end

    describe '#update_attributes' do
      let(:story_item) {Supplejack::StoryItem.new(type: 'foo', sub_type: 'bar')}

      it 'sets the attributes on the StoryItem' do
        story_item.update_attributes(type: 'Mac')

        expect(story_item.type).to eq('Mac')
      end

      it 'saves the StoryItem' do
        expect(story_item).to receive(:save)

        story_item.update_attributes(type: 'Mac')
      end
    end
  end
end
