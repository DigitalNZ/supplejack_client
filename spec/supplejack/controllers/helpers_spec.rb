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
  (@mock_record ||= double(:record).as_null_object).tap do |record|
    record.stub(stubs) unless stubs.empty?
  end
end

class AdvancedSearch < Supplejack::Search
end

module Supplejack
  module Controllers
    describe Helpers do
      before(:each) do
        @c = ActionController::Base.new
        @c.class.send(:include, FakeRoutes)
        @c.class.send(:include, Supplejack::Controllers::Helpers)
        @c.class.send(:include, ActionView::Helpers)
      end

      describe '#search' do
        before(:each) do
          @c.stub(:params) { { text: 'dog' } }
        end

        it 'initializes a search object with the params' do
          Supplejack::Search.should_receive(:new).with(text: 'dog')
          @c.search
        end

        it 'tries to initialize with params[:search] ' do
          @c.stub(:params) { { search: { text: 'cat' } } }
          Supplejack::Search.should_receive(:new).with(text: 'cat')
          @c.search
        end

        it 'initializes the search with the passed params' do
          Supplejack::Search.should_receive(:new).with(text: 'elephant')
          @c.search(text: 'elephant')
        end

        it 'uses the special Search class' do
          Supplejack.stub(:search_klass) { 'AdvancedSearch' }
          AdvancedSearch.should_receive(:new).with(text: 'dog')
          @c.search
        end

        it 'memoizes the search object' do
          @search = Supplejack::Search.new
          Supplejack::Search.should_receive(:new).once.and_return(@search)
          @c.search
          @c.search
        end
      end

      describe 'attribute' do
        context 'nested attributes' do
          before(:each) do
            @user_set = Supplejack::UserSet.new(user: { name: 'Juanito' })
          end

          it 'supports nested attributes' do
            @c.attribute(@user_set, 'user.name').should eq %(<p><strong>User.name: </strong>Juanito</p>)
          end

          it 'correctly uses the translation for the label' do
            I18n.should_receive(:t).with('supplejack_user_sets.user.name', default: 'User.name') { 'By' }
            @c.attribute(@user_set, 'user.name')
          end
        end

        context 'single value' do
          before(:each) do
            @record = mock_record(title: 'Wellington', content_partner: '', description: nil)
          end

          it 'returns the attribute name and its value' do
            @c.attribute(@record, :title).should eq %(<p><strong>Title: </strong>Wellington</p>)
          end

          it 'uses a div instead of a p' do
            @c.attribute(@record, :title, tag: :div).should eq %(<div><strong>Title: </strong>Wellington</div>)
          end

          it 'does not use a tag if tag option is nil' do
            @c.attribute(@record, :title, tag: nil).should eq %(<strong>Title: </strong>Wellington)
          end

          it 'truncates the content to 5 characters' do
            @c.attribute(@record, :title, limit: 8).should eq %(<p><strong>Title: </strong>Welli...</p>)
          end

          it 'puts the label and the field value on seperate lines if label_inle is false' do
            @c.attribute(@record, :title, label_inline: false).should eq %(<p><strong>Title: </strong><br/>Wellington</p>)
          end

          it 'removes the label' do
            @c.attribute(@record, :title, label: false).should eq %(<p>Wellington</p>)
          end

          it 'doesn\'t display anything when the value is nil' do
            @c.attribute(@record, :content_partner).should be_nil
            @c.attribute(@record, :description).should be_nil
          end

          it 'displays span label tag' do
            @c.attribute(@record, :title, label_tag: :span).should eq %(<p><span>Title: </span>Wellington</p>)
          end

          it 'displays label tag with a class' do
            @c.attribute(@record, :title, label_class: 'label').should eq %(<p><strong class="label">Title: </strong>Wellington</p>)
          end

          it 'uses the translation key' do
            I18n.should_receive(:t).with('item.key', default: 'Title').and_return('Title')
            @c.attribute(@record, :title, trans_key: 'item.key')
          end

          context ':link => true' do
            it 'converts it to a URL when value is a url' do
              url = 'http://google.com/images'
              @record = mock_record(landing_url: url)
              @c.attribute(@record, :landing_url, link: true).should eq %(<p><strong>Landing_url: </strong>#{@c.link_to url, url}</p>)
            end

            it 'links to the URL when the value contains both a URL and text' do
              url = 'http://google.com/images'
              @record = mock_record(source: "Image location #{url}")
              @c.attribute(@record, :source, link: true).should eq %(<p><strong>Source: </strong>Image location #{@c.link_to url, url}</p>)
            end

            it 'converts it to a URL with the url pattern in :link and replaces the value' do
              @record = mock_record(subject: ['New Zealand'])
              @c.attribute(@record, :subject, link: '/records?i[subject_text]={{value}}').should eq %(<p><strong>Subject: </strong>#{@c.link_to 'New Zealand', '/records?i[subject_text]=New Zealand'}</p>)
            end

            it 'returns nothing when value is nil' do
              @c.attribute(@record, :description, link: true).should be_nil
            end
          end

          it 'returns nothing when value is "Not specified"' do
            record = mock_record(description: 'Not specified')
            @c.attribute(record, :description).should be_nil
          end

          it 'adds extra_html inside of the <p>' do
            @c.attribute(@record, :title, extra_html: @c.content_tag(:span, 'Hi!')).should eq %(<p><strong>Title: </strong>Wellington<span>Hi!</span></p>)
          end

          context 'default HTML values' do
            it 'uses the tag defined in the config' do
              Supplejack.stub(:attribute_tag) { :span }
              @c.attribute(@record, :title).should eq %(<span><strong>Title: </strong>Wellington</span>)
            end

            it 'uses the label tag defined in the config' do
              Supplejack.stub(:label_tag) { :b }
              @c.attribute(@record, :title).should eq %(<p><b>Title: </b>Wellington</p>)
            end

            it 'uses the label class defined in the config' do
              Supplejack.stub(:label_class) { 'label' }
              @c.attribute(@record, :title).should eq %(<p><strong class="label">Title: </strong>Wellington</p>)
            end
          end
        end

        context 'multiple values' do
          before(:each) do
            @record = mock_record(category: %w[Images Videos])
          end

          it 'displays the values separated by commas' do
            @c.attribute(@record, :category).should eq %(<p><strong>Category: </strong>Images, Videos</p>)
          end

          it 'displays the values separated by another delimiter' do
            @c.attribute(@record, :category, delimiter: ':').should eq %(<p><strong>Category: </strong>Images:Videos</p>)
          end

          it 'limits the amount of values returned' do
            @c.attribute(@record, :category, limit: 1).should eq %(<p><strong>Category: </strong>Images</p>)
          end

          it 'limits the amount of values returned when less than 20' do
            @record.stub(:category) { (1..30).to_a.map(&:to_s) }
            @c.attribute(@record, :category, limit: 10).should eq %(<p><strong>Category: </strong>1, 2, 3, 4, 5, 6, 7, 8, 9, 10</p>)
          end

          it 'generates links for every value' do
            @link1 = @c.link_to('Images', "/records?#{{ i: { category: 'Images' } }.to_query}")
            @link2 = @c.link_to('Videos', "/records?#{{ i: { category: 'Videos' } }.to_query}")
            @c.attribute(@record, :category, link_path: 'records_path').should eq %(<p><strong>Category: </strong>#{@link1}, #{@link2}</p>)
          end

          it 'converts every value to a URL when :link => true and value is a url' do
            url1 = 'http://google.com/images'
            url2 = 'http://yahoo.com/photos'
            @record = mock_record(landing_url: [url1, url2])
            @c.attribute(@record, :landing_url, link: true).should eq %(<p><strong>Landing_url: </strong>#{@c.link_to url1, url1}, #{@c.link_to url2, url2}</p>)
          end

          it 'truncates the sum of all elements in the array' do
            @record = mock_record(description: ['This is a lengthy description', 'Some other stuff'])
            @c.attribute(@record, :description, limit: 40, label: false).should eq '<p>This is a lengthy description, Some o...</p>'
          end

          it 'converts it to a URL with the url pattern in :link and replaces the value for each value' do
            @c.attribute(@record, :category, link: '/records?i[category]={{value}}').should eq %(<p><strong>Category: </strong>#{@c.link_to 'Images', '/records?i[category]=Images'}, #{@c.link_to 'Videos', '/records?i[category]=Videos'}</p>)
          end
        end

        context 'multiple attributes' do
          before(:each) do
            @record = mock_record(category: %w[Images Videos], creator: 'Federico', object_url: nil, source: nil)
          end

          it 'fetches values from multiple attributes' do
            @c.attribute(@record, %i[category creator]).should eq %(<p><strong>Category: </strong>Images, Videos, Federico</p>)
          end

          it 'returns nothing when both values are nil' do
            @c.attribute(@record, %i[object_url source], link: true).should be_nil
          end
        end
      end

      describe '#attribute_link_replacement' do
        it 'generates a link and replaces the value' do
          @c.attribute_link_replacement('Images', '/records?i[category]={{value}}').should eq(@c.link_to('Images', '/records?i[category]=Images'))
        end

        it 'generates a link with the value as text and url' do
          @c.attribute_link_replacement('http://google.comm/images', true).should eq(@c.link_to('http://google.comm/images', 'http://google.comm/images'))
        end

        it 'decodes the link_pattern' do
          @c.attribute_link_replacement('Images', '/records?i[category]=%7B%7Bvalue%7D%7D').should eq(@c.link_to('Images', '/records?i[category]=Images'))
        end
      end

      describe '#next_previous_links' do
        before(:each) do
          @previous_record = mock_record(record_id: 1234)
          @next_record = mock_record(record_id: 5678)
          @record = mock_record(record_id: 1_234_567, previous_record: @previous_record, next_record: @next_record)
          @c.stub(:params) { { search: { text: 'cat' } } }
        end

        it 'returns empty when there is no search query' do
          @c.stub(:params) { {} }
          @c.next_previous_links(@record).should eq ''
        end

        it 'displays the next and previous links' do
          @c.stub(:previous_record_link) { '<a class="prev" href="/records/37674826?search%5Bpath%5D=items&amp;search%5Btext%5D=Forest+fire">Previous result</a>' }
          @c.stub(:next_record_link) { '<a class="next" href="/records/37674826?search%5Bpath%5D=items&amp;search%5Btext%5D=Forest+fire">Next result</a>' }
          @c.next_previous_links(@record).should eq %(<span class=\"nav\">&lt;a class=&quot;next&quot; href=&quot;/records/37674826?search%5Bpath%5D=items&amp;amp;search%5Btext%5D=Forest+fire&quot;&gt;Next result&lt;/a&gt;</span>)
        end
      end
    end
  end
end
