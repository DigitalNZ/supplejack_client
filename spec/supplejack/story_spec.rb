# frozen_string_literal: true

require 'spec_helper'

class SupplejackRecord
  include Supplejack::Record
end

module Supplejack
  describe Story do
    before { Supplejack.stub(:enable_caching) { false } }

    describe '#initialize' do
      Supplejack::Story::ATTRIBUTES.reject { |a| a =~ /_at/ }.each do |attribute|
        it "initializes the #{attribute}" do
          expect(Supplejack::Story.new(attribute => 'value').send(attribute)).to eq 'value'
        end
      end

      it 'handles nil attributes' do
        expect { Supplejack::Story.new(nil).attributes }.not_to raise_error
      end

      it 'initializes a user object' do
        story = Supplejack::Story.new(user: { name: 'Juanito' })
        expect(story.user).to be_a Supplejack::User
        expect(story.user.name).to eq 'Juanito'
      end
    end

    %i[updated_at created_at].each do |field|
      describe "##{field}" do
        let(:story) { Supplejack::Story.new(field => '2012-08-17T10:01:00+12:00') }

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
      let(:story) { Supplejack::Story.new({ name: 'Dogs', description: 'Hi', special_field: true }) }

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

        it 'returns a hash of the set attributes' do
          expect(story.attributes).to include(name: 'Dogs', description: 'Hi')
        end

        it 'doesnt return special_field' do
          expect(story.attributes).to include(special_field: true)
        end

        after { Supplejack.special_story_attributes = %i[] }
      end
    end

    describe '#api_attributes' do
      it 'only returns the fields that can be modified' do
        story = Supplejack::Story.new(name: 'foo', id: 'bar')

        attributes = story.api_attributes

        expect(attributes).to include(:name)
        expect(attributes).not_to include(:id)
      end
    end

    describe '#tag_list' do
      it 'returns a comma sepparated list of tags' do
        expect(Supplejack::Story.new(tags: %w[dog cat]).tag_list).to eq 'dog, cat'
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
        expect(Supplejack::Story.new(user: { api_key: 'foobar' }).api_key).to eq 'foobar'
      end
    end

    describe '#save' do
      context 'Story is a new_record' do
        let(:attributes) { { name: 'Story Name', description: nil, privacy: nil, copyright: nil, featured_at: nil, featured: nil, approved: nil, tags: nil, subjects: nil, record_ids: nil, count: nil, category: nil } }
        let(:user) { { api_key: 'foobar' } }
        let(:story) { Supplejack::Story.new(attributes.merge(user: user)) }

        before do
          expect(Supplejack::Story).to receive(:post).with('/stories', { user_key: 'foobar' }, story: attributes) do
            {
              'id' => 'new-id',
              'name' => attributes[:name],
              'description' => '',
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
          RSpec::Mocks.proxy_for(Supplejack::Story).reset
          Supplejack::Story.stub(:post).and_raise(RestClient::Forbidden.new)

          expect(story.save).to eq false
        end
      end

      context 'story is not new' do
        let(:attributes) { { name: 'Story Name', description: 'desc', privacy: nil, copyright: nil, featured_at: nil, featured: nil, approved: nil, tags: nil, subjects: nil, record_ids: nil, count: nil, category: nil } }
        let(:user) { { api_key: 'foobar' } }
        let(:story) { Supplejack::Story.new(attributes.merge(user: user, id: '123')) }

        before do
          expect(Supplejack::Story).to receive(:patch).with('/stories/123', { user_key: user[:api_key] }, story: attributes) do
            {
              'id' => 'new-id',
              'name' => attributes[:name],
              'description' => 'desc',
              'tags' => [],
              'subjects' => [],
              'contents' => [],
              'category' => nil
            }
          end
        end

        it 'triggers a PATCH request to /stories/123.json with the user set user_key' do
          story.save
        end

        it 'updates the attributes with the response' do
          story.save

          expect(story.description).to eq 'desc'
        end
      end
    end

    describe '#update_attributes' do
      let(:story) { Supplejack::Story.new(name: 'test', description: 'test') }

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
      let(:story) { Supplejack::Story.new(name: 'Foo') }

      it 'updates the attributes on the story' do
        story.attributes = { name: 'Mac' }

        expect(story.name).to eq 'Mac'
      end

      it 'should only update passed attributes' do
        story.id = '12345'
        story.attributes = { name: 'Mac' }

        expect(story.id).to eq '12345'
      end
    end

    describe '#destroy' do
      let(:story) { Supplejack::Story.new(id: '999', user: { api_key: 'keysome' }) }

      it 'executes a delete request to the API with the user set api_key' do
        expect(Supplejack::Story).to receive(:delete).with('/stories/999', user_key: 'keysome')

        expect(story.destroy).to eq(true)
      end

      it 'returns false when the response is not a 200' do
        expect(Supplejack::Story).to receive(:delete).and_raise(RestClient::Forbidden.new)

        expect(story.destroy).to eq(false)
        expect(story.errors).to eq 'Forbidden'
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
        expect(Supplejack::Story).to receive(:get).with('/stories/123456') { { 'id' => 'abc' } }

        story.reload

        expect(story.id).to eq('abc')
      end

      it 'raises Supplejack::StoryNotFound if the Story is not found' do
        expect(Supplejack::Story).to receive(:get).and_raise(RestClient::ResourceNotFound.new)

        expect { story.reload }.to raise_error(Supplejack::StoryNotFound)
      end

      it 'removes the existing @items relation' do
        expect(Supplejack::Story).to receive(:get).with('/stories/123456') { { 'id' => 'abc' } }

        story.items
        story.reload

        expect(story.instance_variable_get('@items')).to be_nil
      end
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
        expect(Supplejack::Story).to receive(:get).and_return(
          'sets' => [
            Supplejack::User.new(api_key: api_key).attributes,
            Supplejack::User.new(api_key: api_key).attributes
          ]
        )

        expect(Supplejack::Story.all_public_stories.count).to eq(2)
      end

      it 'includes stories metadata if :meta_included option passed' do
        expect(Supplejack::Story).to receive(:get).and_return(
          'sets' => [
            Supplejack::User.new(api_key: api_key).attributes,
            Supplejack::User.new(api_key: api_key).attributes
          ],
          'per_page' => 10,
          'page' => 1,
          'total' => 2,
          'total_filtered' => 2
        )
        expect(Supplejack::Story.all_public_stories(meta_included: true)).to include('sets', 'total_filtered', 'total', 'page', 'per_page')
      end
    end

    describe '#find' do
      let(:attributes) do
        {
          name: 'foo',
          description: 'desc',
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
          category: nil
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
      it 'initializes the Story and sets the user api_key' do
        expect(Supplejack::Story).to receive(:get).with('/stories/123abc', user_key: '98765').and_return(attributes)

        story = Supplejack::Story.find('123abc', user_key: '98765')

        expect(story.api_key).to eq('98765')
      end

      it 'raises a Supplejack::StoryNotFound' do
        Supplejack::Story.stub(:get).and_raise(RestClient::ResourceNotFound)

        expect { Supplejack::Story.find(id: '123') }.to raise_error(Supplejack::StoryNotFound)
      end
    end

    describe '#featured' do
      it 'fetches stories from the api' do
        Supplejack::Story.should_receive(:get).with('/stories/featured')
        Supplejack::Story.featured
      end

      context 'when RestClient service unavailable' do
        before { allow(Supplejack::Story).to receive(:get).and_raise(RestClient::ServiceUnavailable) }

        it 'fetches stories from the api' do
          expect { Supplejack::Story.featured }.to raise_error(Supplejack::ApiNotAvailable)
        end
      end
    end
  end
end
