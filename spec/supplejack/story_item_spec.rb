# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe StoryItem do
    describe '#initialize' do
      it 'accepts a hash of attributes' do
        described_class.new(type: 'embed', sub_type: 'supplejack_user')
      end

      it 'accepts a hash with string keys' do
        expect(described_class.new('type' => 'embed', 'sub_type' => 'supplejack_user').type).to eq('embed')
      end

      it 'handles nil attributes' do
        expect(described_class.new(nil).type).to be_nil
      end

      Supplejack::StoryItem::ATTRIBUTES.each do |attribute|
        it "initializes the attribute #{attribute}" do
          expect(described_class.new(attribute => 'value').send(attribute)).to eq 'value'
        end
      end
    end

    describe '#save' do
      let(:item) { described_class.new(type: 'embed', sub_type: 'supplejack_user', story_id: '1234', api_key: 'abc') }

      context 'when item is new ' do
        it 'triggers a POST request to create a story_item with the story api_key' do
          expect(item).to receive(:post).with('/stories/1234/items', { user_key: 'abc' }, story_item: { meta: {}, type: 'embed', sub_type: 'supplejack_user' })

          expect(item.save).to eq(true)
        end
      end

      context 'with existing item' do
        it 'triggers a PATCH request to update a story_item with the story api_key' do
          item.id = 1
          expect(item).to receive(:patch).with('/stories/1234/items/1', { user_key: 'abc' }, story_item: { meta: {}, type: 'embed', sub_type: 'supplejack_user' })

          expect(item.save).to eq(true)
        end
      end

      context 'when HTTP error is raised' do
        before { allow(item).to receive(:post).and_raise(RestClient::Forbidden.new) }

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
      let(:item) { described_class.new(story_id: '1234', api_key: 'abc', id: 5) }

      it 'triggers a DELETE request with the story api_key' do
        expect(item).to receive(:delete).with('/stories/1234/items/5', user_key: 'abc')

        item.destroy
      end

      context 'when HTTP error is raised' do
        before { allow(item).to receive(:delete).and_raise(RestClient::Forbidden.new) }

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
      let(:story_item) { described_class.new(type: 'foo', sub_type: 'bar') }

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
