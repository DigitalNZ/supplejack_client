# frozen_string_literal: true

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

module Supplejack
  describe Story do
    before { allow(Supplejack).to receive(:enable_caching).and_return(false) }

    describe '#initialize' do
      Supplejack::Story::ATTRIBUTES.reject { |a| a =~ /_at/ }.each do |attribute|
        it "initializes the #{attribute}" do
          expect(described_class.new(attribute => 'value').send(attribute)).to eq 'value'
        end
      end

      it 'handles nil attributes' do
        expect { described_class.new(nil).attributes }.not_to raise_error
      end

      it 'initializes a user object' do
        story = described_class.new(user: { name: 'Juanito' })
        expect(story.user).to be_a Supplejack::User
        expect(story.user.name).to eq 'Juanito'
      end
    end

    %i[updated_at created_at].each do |field|
      describe "##{field}" do
        let(:story) { described_class.new(field => '2012-08-17T10:01:00+12:00') }

        it 'converts it into a time object' do
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
      let(:story) { described_class.new({ name: 'Dogs', description: 'Hi', special_field: true }) }

      context 'when Supplejack special_story_attributes is not configured' do
        it 'returns a hash of the set attributes' do
          expect(story.attributes).to include(name: 'Dogs', description: 'Hi')
        end

        it 'doesnt return special_field' do
          expect(story.attributes).not_to include(special_field: true)
        end
      end

      context 'when Supplejack special_story_attributes is configured' do
        before { Supplejack.special_story_attributes = %i[special_field] }

        after { Supplejack.special_story_attributes = %i[] }

        it 'returns a hash of the set attributes' do
          expect(story.attributes).to include(name: 'Dogs', description: 'Hi')
        end

        it 'doesnt return special_field' do
          expect(story.attributes).to include(special_field: true)
        end
      end
    end

    describe '#api_attributes' do
      it 'only returns the fields that can be modified' do
        story = described_class.new(name: 'foo', id: 'bar')

        attributes = story.api_attributes

        expect(attributes).to include(:name)
        expect(attributes).not_to include(:id)
      end
    end

    describe '#tag_list' do
      it 'returns a comma sepparated list of tags' do
        expect(described_class.new(tags: %w[dog cat]).tag_list).to eq 'dog, cat'
      end
    end

    describe '#private?' do
      it 'returns true when the privacy is private' do
        expect(described_class.new(privacy: 'private').private?).to eq true
      end

      it 'returns false when the privacy is something else' do
        expect(described_class.new(privacy: 'public').private?).to eq false
      end
    end

    describe '#public?' do
      it 'returns false when the privacy is private' do
        expect(described_class.new(privacy: 'private').public?).to eq false
      end

      it 'returns true when the privacy is public' do
        expect(described_class.new(privacy: 'public').public?).to eq true
      end
    end

    describe '#hidden?' do
      it 'returns false when the privacy is not hidden' do
        expect(described_class.new(privacy: 'public').hidden?).to eq false
      end

      it 'returns true when the privacy is hidden' do
        expect(described_class.new(privacy: 'hidden').hidden?).to eq true
      end
    end

    describe '#new_record?' do
      it "returns true when the user_set doesn't have a id" do
        expect(described_class.new.new_record?).to eq true
      end

      it 'returns false when the user_set has a id' do
        expect(described_class.new(id: '1234abc').new_record?).to eq false
      end
    end

    describe '#api_key' do
      it 'returns the users api_key' do
        expect(described_class.new(user: { api_key: 'foobar' }).api_key).to eq 'foobar'
      end
    end

    describe '#save' do
      context 'when story is a new_record' do
        let(:attributes) { { name: 'Story Name', description: nil, errors: nil, privacy: nil, copyright: nil, featured_at: nil, featured: nil, approved: nil, tags: nil, subjects: nil, record_ids: nil, count: nil, category: nil } }
        let(:user) { { api_key: 'foobar' } }
        let(:story) { described_class.new(attributes.merge(user:)) }

        before do
          allow(described_class).to receive(:post).with(
            '/stories',
            { user_key: 'foobar' },
            { story: attributes }
          ) do
            {
              'id' => 'new-id',
              'name' => attributes[:name],
              'description' => '',
              'errors' => nil,
              'tags' => [],
              'subjects' => [],
              'contents' => [],
              'category' => nil
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
          RSpec::Mocks.space.proxy_for(described_class).reset
          allow(described_class).to receive(:post).and_raise(RestClient::Forbidden.new)

          expect(story.save).to eq false
        end
      end

      context 'when story is not new' do
        let(:attributes) { { name: 'Story Name', description: 'desc', errors: nil, privacy: nil, copyright: nil, featured_at: nil, featured: nil, approved: nil, tags: nil, subjects: nil, record_ids: nil, count: nil, category: nil } }
        let(:user) { { api_key: 'foobar' } }
        let(:story) { described_class.new(attributes.merge(user:, id: '123')) }

        before do
          allow(described_class).to receive(:patch).with(
            '/stories/123',
            { user_key: user[:api_key] },
            { story: attributes }
          ) do
            {
              'id' => 'new-id',
              'name' => attributes[:name],
              'description' => 'desc',
              'errors' => nil,
              'tags' => [],
              'subjects' => [],
              'contents' => [],
              'category' => nil
            }
          end
        end

        it 'updates the attributes with the response' do
          story.save

          expect(story.description).to eq 'desc'
        end
      end

      context 'when request fails' do
        let(:story) { described_class.new({ name: 'Story Name', user: { api_key: 'foobar' }, id: '123' }) }

        it 'triggers a POST request to reposition_items' do
          allow(described_class).to receive(:patch).and_return({ 'errors' => 'save failed' })

          expect(story.save).to be false
          expect(story.errors).to eq 'save failed'
        end
      end
    end

    describe '#reposition_items' do
      let(:user) { { api_key: 'foobar' } }
      let(:story) { described_class.new({ name: 'Story Name', description: 'desc', user:, id: '123' }) }
      let(:reposition_attributes) { [{ id: '111', position: 1 }, { id: '112', position: 2 }] }

      context 'when request is successful' do
        it 'triggers a POST request to reposition_items' do
          expect(described_class).to receive(:post).with('/stories/123/reposition_items', { user_key: user[:api_key] }, items: reposition_attributes)

          story.reposition_items(reposition_attributes)
        end
      end

      context 'when request fails' do
        it 'triggers a POST request to reposition_items' do
          allow(described_class).to receive(:post).and_return({ 'errors' => 'repositioning failed' })

          expect(story.reposition_items(reposition_attributes)).to be false
          expect(story.errors).to eq 'repositioning failed'
        end
      end
    end

    describe '#multiple_add' do
      let(:user) { { api_key: 'foobar' } }
      let(:story) { described_class.new({ name: 'Story Name', description: 'desc', user:, id: '123' }) }
      let(:stories) { [{ id: '1', items: [] }, { id: '2', items: [] }] }

      it 'triggers a POST request to multiple_add' do
        expect(described_class).to receive(:post).with('/stories/multiple_add', { user_key: user[:api_key] }, stories:)

        story.multiple_add(stories)
      end
    end

    describe '#multiple_remove' do
      let(:user) { { api_key: 'foobar' } }
      let(:story) { described_class.new({ name: 'Story Name', description: 'desc', user:, id: '123' }) }
      let(:stories) { [{ id: '1', items: [1] }, { id: '2', items: [2] }] }

      it 'triggers a POST request to multiple_add' do
        expect(described_class).to receive(:post).with('/stories/multiple_remove', { user_key: user[:api_key] }, stories:)

        story.multiple_remove(stories)
      end
    end

    describe '#update_attributes' do
      let(:story) { described_class.new(name: 'test', description: 'test') }

      it 'sets the attributes on the Story' do
        story.update_attributes(name: 'Mac')

        expect(story.name).to eq('Mac')
      end

      it 'saves the Story' do
        expect(story).to receive(:save)

        story.update_attributes(name: 'Mac')
      end
    end

    describe '#attributes=' do
      let(:story) { described_class.new(name: 'Foo') }

      it 'updates the attributes on the story' do
        story.attributes = { name: 'Mac' }

        expect(story.name).to eq 'Mac'
      end

      it 'updates only passed attributes' do
        story.id = '12345'
        story.attributes = { name: 'Mac' }

        expect(story.id).to eq '12345'
      end
    end

    describe '#destroy' do
      let(:story) { described_class.new(id: '999', user: { api_key: 'keysome' }) }

      it 'executes a delete request to the API with the user set api_key' do
        expect(described_class).to receive(:delete).with('/stories/999', user_key: 'keysome')

        expect(story.destroy).to eq(true)
      end

      it 'returns false when the response is not a 200' do
        allow(described_class).to receive(:delete).and_raise(RestClient::Forbidden.new)

        expect(story.destroy).to eq(false)
        expect(story.errors).to eq 'Forbidden'
      end

      it 'returns false when it is a new user set' do
        allow(story).to receive(:new_record?).and_return(true)

        expect(described_class).not_to receive(:delete)
        expect(story.destroy).to eq(false)
      end
    end

    describe '#reload' do
      let(:story) { described_class.new(id: '123456') }

      it 'fetches the set from the api and repopulates the set' do
        allow(described_class).to receive(:get).with('/stories/123456').and_return({ 'id' => 'abc' })

        story.reload

        expect(story.id).to eq('abc')
      end

      it 'raises Supplejack::StoryNotFound if the Story is not found' do
        allow(described_class).to receive(:get).and_raise(RestClient::ResourceNotFound.new)

        expect { story.reload }.to raise_error(Supplejack::StoryNotFound)
      end

      it 'removes the existing @items relation' do
        allow(described_class).to receive(:get).with('/stories/123456').and_return({ 'id' => 'abc' })

        story.items
        story.reload

        expect(story.instance_variable_get('@items')).to be_nil
      end
    end

    describe '#viewable_by?' do
      let(:api_key) { '123' }
      let(:user) { { api_key: } }

      it 'returns true when the Story is public' do
        story = described_class.new(privacy: 'public')

        expect(story.viewable_by?(nil)).to eq(true)
      end

      it 'returns true when the user_set is hidden' do
        story = described_class.new(privacy: 'hidden')

        expect(story.viewable_by?(nil)).to eq(true)
      end

      context 'when set is private' do
        let(:story) { described_class.new(privacy: 'private', user:) }

        it 'returns false when the user is not present' do
          expect(story.viewable_by?(nil)).to eq(false)
        end

        it 'returns true when the user has the same api_key as the user_set' do
          expect(story.viewable_by?(Supplejack::User.new(user))).to eq(true)
        end

        it 'returns false if both the api_key in the user and the set are nil' do
          user = { api_key: nil }
          story = described_class.new(privacy: 'private', user:)

          expect(story.viewable_by?(Supplejack::User.new(user))).to eq(false)
        end
      end
    end

    describe '#owned_by?' do
      let(:api_key) { '123456' }
      let(:user) { Supplejack::User.new(api_key:) }
      let(:users_story) { described_class.new(user: { api_key: }) }
      let(:other_story) { described_class.new(user: { api_key: '123' }) }
      let(:nil_api_key_story) { described_class.new(user: { api_key: nil }) }

      it "returns true when the users api_key is the same as the set's" do
        expect(users_story.owned_by?(user)).to eq(true)
      end

      it 'returns false when the set and user have different api_keys' do
        expect(other_story.owned_by?(user)).to eq(false)
      end

      it 'returns false when both keys are nil' do
        expect(nil_api_key_story.owned_by?(user)).to eq(false)
      end
    end

    describe '#all_public_stories' do
      let(:api_key) { '123456' }

      it 'returns an array with all stories from /stories/moderations endpoint' do
        allow(described_class).to receive(:get).and_return(
          'sets' => [
            Supplejack::User.new(api_key:).attributes,
            Supplejack::User.new(api_key:).attributes
          ]
        )

        expect(described_class.all_public_stories.count).to eq(2)
      end

      it 'includes stories metadata if :meta_included option passed' do
        allow(described_class).to receive(:get).and_return(
          'sets' => [Supplejack::User.new(api_key:).attributes, Supplejack::User.new(api_key:).attributes],
          'per_page' => 10, 'page' => 1,
          'total' => 2, 'total_filtered' => 2
        )

        expect(described_class.all_public_stories(meta_included: true)).to include('sets', 'total_filtered', 'total', 'page', 'per_page')
      end
    end

    describe '#history' do
      let(:api_key) { '123456' }
      let(:story) { described_class.new(id: 'story_1') }
      let(:response) do
        [
          {
            id: 'moderation_record_id_1',
            created_at: '2023-03-23T13:11:44.828+13:00',
            updated_at: '2023-03-23T13:11:44.828+13:00',
            user: { id: 'user_id_1', username: 'username_1' },
            state: 'Remoderate'
          },
          {
            id: 'moderation_record_id_2',
            created_at: '2023-03-23T23:22:44.828+23:00',
            updated_at: '2023-03-23T23:22:44.828+23:00',
            user: { id: 'user_id_2', username: 'username_2' },
            state: 'Remoderate'
          }
        ]
      end

      it 'returns an array with moderation records' do
        allow(described_class).to receive(:get).and_return(response)

        expect(story.history(user_key: api_key).count).to eq(2)
      end
    end

    describe '#find' do
      let(:attributes) do
        {
          name: 'foo',
          description: 'desc',
          errors: nil,
          privacy: nil,
          copyright: nil,
          featured: nil,
          approved: nil,
          tags: nil,
          subjects: nil,
          record_ids: nil,
          contents: nil,
          created_at: nil,
          featured_at: nil,
          updated_at: nil,
          number_of_items: nil,
          id: nil,
          cover_thumbnail: nil,
          creator: 'Wilfred',
          count: nil,
          user_id: nil,
          username: nil,
          category: nil,
          state: nil
        }
      end

      it 'fetches the Story from the API' do
        allow(described_class).to receive(:get).with('/stories/123abc', {}).and_return(attributes)

        described_class.find('123abc')
      end

      it 'initializes a Story object' do
        allow(described_class).to receive(:get).with('/stories/123abc', {}).and_return(attributes)

        story = described_class.find('123abc')

        expect(story.attributes).to eq(attributes.symbolize_keys)
      end

      # I've removed this functionality because I don't understand the use case
      # If we _do_ end up needing it in the future we can re add it
      it 'initializes the Story and sets the user api_key' do
        allow(described_class).to receive(:get).with('/stories/123abc', { user_key: '98765' }).and_return(attributes)

        story = described_class.find('123abc', user_key: '98765')

        expect(story.api_key).to eq('98765')
      end

      it 'raises a Supplejack::StoryNotFound' do
        allow(described_class).to receive(:get).and_raise(RestClient::ResourceNotFound)

        expect { described_class.find('123') }.to raise_error(Supplejack::StoryNotFound)
      end
    end

    describe '#featured' do
      it 'fetches stories from the api' do
        expect(described_class).to receive(:get).with('/stories/featured')
        described_class.featured
      end

      context 'when RestClient service unavailable' do
        before { allow(described_class).to receive(:get).and_raise(RestClient::ServiceUnavailable) }

        it 'fetches stories from the api' do
          expect { described_class.featured }.to raise_error(Supplejack::ApiNotAvailable)
        end
      end
    end
  end
end
