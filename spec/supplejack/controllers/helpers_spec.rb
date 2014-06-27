# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'
require 'action_view'
require 'action_controller'
require 'rails_autolink/helpers'

include ActionView::Context

class AdvancedSearch < Supplejack::Search
end

module Supplejack
  module Controllers
    describe Helpers do

      before(:each) do
        @c = ActionController::Base.new
        @c.class.send(:include, Supplejack::Controllers::Helpers)
        @c.class.send(:include, ActionView::Helpers)
      end

      describe '#search' do
        before(:each) do
          @c.stub(:params) {{:text => 'dog'}}
        end

        it 'initializes a search object with the params' do
          Supplejack::Search.should_receive(:new).with({:text => 'dog'})
          @c.search
        end

        it 'tries to initialize with params[:search] ' do
          @c.stub(:params) {{:search => {:text => 'cat'}}}
          Supplejack::Search.should_receive(:new).with({:text => 'cat'})
          @c.search
        end

        it 'initializes the search with the passed params' do
          Supplejack::Search.should_receive(:new).with({:text => 'elephant'})
          @c.search({:text => 'elephant'})
        end

        it 'uses the special Search class' do
          Supplejack.stub(:search_klass) { 'AdvancedSearch' }
          AdvancedSearch.should_receive(:new).with({:text => 'dog'})
          @c.search
        end

        it 'memoizes the search object' do
          @search = Supplejack::Search.new
          Supplejack::Search.should_receive(:new).once.and_return(@search)
          @c.search
          @c.search
        end
      end

    end
  end
end
