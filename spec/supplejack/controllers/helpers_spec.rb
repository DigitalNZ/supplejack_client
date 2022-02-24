# frozen_string_literal: false

require 'spec_helper'
require 'action_view'
require 'action_controller'
require 'rails_autolink/helpers'

module FakeRoutes
  include ActionView::Context

  def records_path(options = {})
    path = '/records'
    path += "?#{options.to_query}" if options.any?
    path
  end

  def record_path(id, options = {})
    path = "/records/#{id}"
    path += "?#{options.to_query}" if options.any?
    path
  end

  def url_for(options = {})
    options
  end
end

def mock_record(stubs = {})
  # rubocop:disable RSpec/VerifiedDoubles
  (@mock_record ||= double(:record).as_null_object).tap do |record|
    unless stubs.empty?
      stubs.each do |key, value|
        allow(record).to receive(key).and_return(value)
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

class AdvancedSearch < Supplejack::Search
end

module Supplejack
  module Controllers
    describe Helpers do
      let(:controller) { ActionController::Base.new }

      before do
        controller.class.send(:include, FakeRoutes)
        controller.class.send(:include, described_class)
        controller.class.send(:include, ActionView::Helpers)
      end

      describe '#search' do
        before { allow(controller).to receive(:params).and_return({ text: 'dog' }) }

        it 'initializes a search object with the params' do
          expect(Supplejack::Search).to receive(:new).with({ text: 'dog' })

          controller.search
        end

        it 'tries to initialize with params[:search] ' do
          allow(controller).to receive(:params).and_return({ search: { text: 'cat' } })

          expect(Supplejack::Search).to receive(:new).with(text: 'cat')

          controller.search
        end

        it 'initializes the search with the passed params' do
          expect(Supplejack::Search).to receive(:new).with(text: 'elephant')

          controller.search(text: 'elephant')
        end

        it 'uses the special Search class' do
          allow(Supplejack).to receive(:search_klass).and_return('AdvancedSearch')
          expect(AdvancedSearch).to receive(:new).with(text: 'dog')

          controller.search
        end

        it 'memoizes the search object' do
          expect(Supplejack::Search).to receive(:new).once.and_return(Supplejack::Search.new)

          controller.search
          controller.search
        end
      end

      describe 'attribute' do
        context 'with nested attributes' do
          let(:user_set) { Supplejack::UserSet.new(user: { name: 'Juanito' }) }

          it 'supports nested attributes' do
            expect(controller.attribute(user_set, 'user.name')).to eq %(<p><strong>User.name: </strong>Juanito</p>)
          end

          it 'correctly uses the translation for the label' do
            allow(I18n).to receive(:t).with('supplejack_user_sets.user.name', default: 'User.name').and_return('By')

            controller.attribute(user_set, 'user.name')
          end
        end

        context 'with single value' do
          let(:record) { mock_record(title: 'Wellington', content_partner: '', description: nil) }

          it 'returns the attribute name and its value' do
            expect(controller.attribute(record, :title)).to eq %(<p><strong>Title: </strong>Wellington</p>)
          end

          it 'uses a div instead of a p' do
            expect(controller.attribute(record, :title, tag: :div)).to eq %(<div><strong>Title: </strong>Wellington</div>)
          end

          it 'does not use a tag if tag option is nil' do
            expect(controller.attribute(record, :title, tag: nil)).to eq %(<strong>Title: </strong>Wellington)
          end

          it 'truncates the content to 5 characters' do
            expect(controller.attribute(record, :title, limit: 8)).to eq %(<p><strong>Title: </strong>Welli...</p>)
          end

          it 'puts the label and the field value on seperate lines if label_inle is false' do
            expect(controller.attribute(record, :title, label_inline: false)).to eq %(<p><strong>Title: </strong><br/>Wellington</p>)
          end

          it 'removes the label' do
            expect(controller.attribute(record, :title, label: false)).to eq %(<p>Wellington</p>)
          end

          it 'doesn\'t display content_partner' do
            expect(controller.attribute(record, :content_partner)).to be nil
          end

          it 'doesn\'t display description' do
            expect(controller.attribute(record, :description)).to be nil
          end

          it 'displays span label tag' do
            expect(controller.attribute(record, :title, label_tag: :span)).to eq %(<p><span>Title: </span>Wellington</p>)
          end

          it 'displays label tag with a class' do
            expect(controller.attribute(record, :title, label_class: 'label')).to eq %(<p><strong class="label">Title: </strong>Wellington</p>)
          end

          it 'uses the translation key' do
            allow(I18n).to receive(:t).with('item.key', default: 'Title').and_return('Title')

            controller.attribute(record, :title, trans_key: 'item.key')
          end

          context 'when :link => true' do
            it 'converts it to a URL when value is a url' do
              url = 'http://google.com/images'
              record = mock_record(landing_url: url)

              expect(controller.attribute(record, :landing_url, link: true)).to eq %(<p><strong>Landing_url: </strong>#{controller.link_to url, url}</p>)
            end

            it 'links to the URL when the value contains both a URL and text' do
              url = 'http://google.com/images'
              record = mock_record(source: "Image location #{url}")

              expect(controller.attribute(record, :source, link: true)).to eq %(<p><strong>Source: </strong>Image location #{controller.link_to url, url}</p>)
            end

            it 'converts it to a URL with the url pattern in :link and replaces the value' do
              record = mock_record(subject: ['New Zealand'])

              expect(controller.attribute(record, :subject, link: '/records?i[subject_text]={{value}}')).to eq %(<p><strong>Subject: </strong>#{controller.link_to 'New Zealand', '/records?i[subject_text]=New Zealand'}</p>)
            end

            it 'returns nothing when value is nil' do
              expect(controller.attribute(record, :description, link: true)).to be nil
            end
          end

          it 'returns nothing when value is "Not specified"' do
            record = mock_record(description: 'Not specified')

            expect(controller.attribute(record, :description)).to be nil
          end

          it 'adds extra_html inside of the <p>' do
            expect(controller.attribute(record, :title, extra_html: controller.content_tag(:span, 'Hi!'))).to eq %(<p><strong>Title: </strong>Wellington<span>Hi!</span></p>)
          end

          context 'when default HTML values' do
            it 'uses the tag defined in the config' do
              allow(Supplejack).to receive(:attribute_tag).and_return(:span)

              expect(controller.attribute(record, :title)).to eq %(<span><strong>Title: </strong>Wellington</span>)
            end

            it 'uses the label tag defined in the config' do
              allow(Supplejack).to receive(:label_tag).and_return(:b)

              expect(controller.attribute(record, :title)).to eq %(<p><b>Title: </b>Wellington</p>)
            end

            it 'uses the label class defined in the config' do
              allow(Supplejack).to receive(:label_class).and_return('label')

              expect(controller.attribute(record, :title)).to eq %(<p><strong class="label">Title: </strong>Wellington</p>)
            end
          end
        end

        context 'with multiple values' do
          let(:record) { mock_record(category: %w[Images Videos]) }

          it 'displays the values separated by commas' do
            expect(controller.attribute(record, :category)).to eq %(<p><strong>Category: </strong>Images, Videos</p>)
          end

          it 'displays the values separated by another delimiter' do
            expect(controller.attribute(record, :category, delimiter: ':')).to eq %(<p><strong>Category: </strong>Images:Videos</p>)
          end

          it 'limits the amount of values returned' do
            expect(controller.attribute(record, :category, limit: 1)).to eq %(<p><strong>Category: </strong>Images</p>)
          end

          it 'limits the amount of values returned when less than 20' do
            allow(record).to receive(:category) { (1..30).to_a.map(&:to_s) }

            expect(controller.attribute(record, :category, limit: 10)).to eq %(<p><strong>Category: </strong>1, 2, 3, 4, 5, 6, 7, 8, 9, 10</p>)
          end

          it 'generates links for every value' do
            link1 = controller.link_to('Images', "/records?#{{ i: { category: 'Images' } }.to_query}")
            link2 = controller.link_to('Videos', "/records?#{{ i: { category: 'Videos' } }.to_query}")

            expect(controller.attribute(record, :category, link_path: 'records_path')).to eq %(<p><strong>Category: </strong>#{link1}, #{link2}</p>)
          end

          it 'converts every value to a URL when :link => true and value is a url' do
            url1 = 'http://google.com/images'
            url2 = 'http://yahoo.com/photos'
            record = mock_record(landing_url: [url1, url2])

            expect(controller.attribute(record, :landing_url, link: true)).to eq %(<p><strong>Landing_url: </strong>#{controller.link_to url1, url1}, #{controller.link_to url2, url2}</p>)
          end

          it 'truncates the sum of all elements in the array' do
            record = mock_record(description: ['This is a lengthy description', 'Some other stuff'])

            expect(controller.attribute(record, :description, limit: 40, label: false)).to eq '<p>This is a lengthy description, Some o...</p>'
          end

          it 'converts it to a URL with the url pattern in :link and replaces the value for each value' do
            expect(controller.attribute(record, :category, link: '/records?i[category]={{value}}')).to eq %(<p><strong>Category: </strong>#{controller.link_to 'Images', '/records?i[category]=Images'}, #{controller.link_to 'Videos', '/records?i[category]=Videos'}</p>)
          end
        end

        context 'with multiple attributes' do
          let(:record) { mock_record(category: %w[Images Videos], creator: 'Federico', object_url: nil, source: nil) }

          it 'fetches values from multiple attributes' do
            expect(controller.attribute(record, %i[category creator])).to eq %(<p><strong>Category: </strong>Images, Videos, Federico</p>)
          end

          it 'returns nothing when both values are nil' do
            expect(controller.attribute(record, %i[object_url source], link: true)).to be nil
          end
        end
      end

      describe '#attribute_link_replacement' do
        it 'generates a link and replaces the value' do
          expect(controller.attribute_link_replacement('Images', '/records?i[category]={{value}}')).to eq(controller.link_to('Images', '/records?i[category]=Images'))
        end

        it 'generates a link with the value as text and url' do
          expect(controller.attribute_link_replacement('http://google.comm/images', true)).to eq(controller.link_to('http://google.comm/images', 'http://google.comm/images'))
        end

        it 'decodes the link_pattern' do
          expect(controller.attribute_link_replacement('Images', '/records?i[category]=%7B%7Bvalue%7D%7D')).to eq(controller.link_to('Images', '/records?i[category]=Images'))
        end
      end

      describe '#next_previous_links' do
        let(:previous_record) { mock_record(record_id: 1234) }
        let(:next_record)     { mock_record(record_id: 5678) }
        let(:record)          { mock_record(record_id: 1_234_567, previous_record: previous_record, next_record: next_record) }

        before { allow(controller).to receive(:params).and_return({ search: { text: 'cat' } }) }

        it 'returns empty when there is no search query' do
          allow(controller).to receive(:params).and_return({})

          expect(controller.next_previous_links(record)).to eq ''
        end

        it 'displays the next and previous links' do
          allow(controller).to receive(:previous_record_link).and_return('<a class="prev" href="/records/37674826?search%5Bpath%5D=items&amp;search%5Btext%5D=Forest+fire">Previous result</a>')
          allow(controller).to receive(:next_record_link).and_return('<a class="next" href="/records/37674826?search%5Bpath%5D=items&amp;search%5Btext%5D=Forest+fire">Next result</a>')

          expect(controller.next_previous_links(record)).to eq %(<span class=\"nav\">&lt;a class=&quot;next&quot; href=&quot;/records/37674826?search%5Bpath%5D=items&amp;amp;search%5Btext%5D=Forest+fire&quot;&gt;Next result&lt;/a&gt;</span>)
        end
      end
    end
  end
end
