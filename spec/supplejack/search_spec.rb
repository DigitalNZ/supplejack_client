# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

class TestRecord
  def initialize(attributes={})
  end
end

class TestItem
  def initialize(attributes={})
  end
end

module Supplejack
  describe Search do

    describe '#initalize' do
      it 'doesn\'t break when initalized with nil' do
        Search.new(nil)
      end
    end

    describe '#params' do
      it 'defaults to facets set in initializer' do
        Supplejack.stub(:facets) { ['location', 'description'] }
        Search.new.api_params[:facets].should eq('location,description')
      end

      it 'sets the facets through the params' do
        Search.new(:facets => 'name,description').api_params[:facets].should eq('name,description')
      end

      it 'defaults to facets_per_page set in initializer' do
        Supplejack.stub(:facets_per_page) { 33 }
        Search.new.api_params[:facets_per_page].should eq 33
      end

      it 'sets the facets_per_page through the params' do
        Search.new(:facets_per_page => 13).api_params[:facets_per_page].should eq 13
      end

      it 'deletes rails specific params' do
        params = Search.new(:controller => 'records', :action => 'index').api_params
        params.should_not have_key(:controller)
        params.should_not have_key(:action)
      end
    end

    describe '#text' do
      it 'returns the search text' do
        Search.new(:text => 'dog').text.should eq('dog')
      end
    end

    # describe '#geo_bbox' do
    # end
    
    # describe "#record_type" do
    # end

    describe '#page' do
      it 'defaults to 1' do
        Search.new.page.should eq 1
      end

      it 'converts the page to a number' do
        Search.new(:page => '2').page.should eq 2
      end
    end

    describe '#per_page' do
      it 'defaults to the per_page in the initializer' do
        Supplejack.stub(:per_page) { 16 }
        Search.new.per_page.should eq 16
      end

      it 'sers the per_page through the params' do
        Search.new(:per_page => '3').per_page.should eq 3
      end
    end

    describe '#sort' do
      it 'returns the field to sort on' do
        Search.new(:sort => 'content_partner').sort.should eq 'content_partner'
      end

      it 'returns nil when not set' do
        Search.new.sort.should be_nil
      end
    end

    describe '#direction' do
      it 'returns the direction to sort the results' do
        Search.new(:direction => 'asc').direction.should eq 'asc'
      end

      it 'returns nil when not set' do
        Search.new.direction.should be_nil
      end
    end

    # describe "#custom_search" do
    # end
    
    describe '#search_attributes' do
      it 'sets the filter defined in Supplejack.search_attributes with its current value' do
        Supplejack.stub(:search_attributes) { [:location] }
        Search.new(:i => {:location => 'Wellington'}).location.should eq 'Wellington'
      end
    end

    describe '#filters' do
      before(:each) do
        @filters = {:location => 'Wellington', :country => 'New Zealand'}
      end

      it 'returns filters in a array format by default' do
        Search.new(:i => @filters).filters.should include([:location, 'Wellington'], [:country, 'New Zealand'])
      end

      it 'returns a hash of the current search filters' do
        Search.new(:i => @filters).filters(:format => :hash).should include(@filters)
      end

      it 'expands filters that contain arrays' do
        @filters = {:location => ['Wellington', 'Auckland']}
        Search.new(:i => @filters).filters.should include([:location, 'Wellington'], [:location, 'Auckland'])
      end

      it 'removes the location filter' do
        @filters = {:location => ['Wellington', 'Auckland']}
        Search.new(:i => @filters).filters(:except => [:location]).should_not include([:location, 'Wellington'], [:location, 'Auckland'])
      end
    end

    describe "#facets" do
      before(:each) do
        @search = Search.new
        Supplejack.facets = [:location]
        @facets_hash = {"location" => {"Wellington" => 100}, "mayor" => {"Brake, Brian" => 20}}
        @search.instance_variable_set(:@response, {"search" => {"facets" => @facets_hash}})
      end

      it 'executes the request only once' do
        @search.should_receive(:execute_request).once
        @search.facets
        @search.facets
      end

      it 'handles a failed request from the API' do
        @search.instance_variable_set(:@response, {'search' => {}})
        @search.facets.should be_empty
      end

      it 'initializes a facet object for each facet' do
        Supplejack::Facet.should_receive(:new).with('location', {'Wellington' => 100})
        Supplejack::Facet.should_receive(:new).with('mayor', {'Brake, Brian' => 20})
        @search.facets
      end

      it 'orders the facets based on the order set in the initializer' do
        Supplejack.stub(:facets) { [:mayor, :location] }
        @search.facets.first.name.should eq 'mayor'
        @search.facets.last.name.should eq 'location'
      end

      it 'orders the facets the other way around' do
        Supplejack.stub(:facets) { [:location, :mayor] }
        @search.facets.first.name.should eq 'location'
        @search.facets.last.name.should eq 'mayor'
      end

      it 'returns the facet values' do
        @search.facets.first.values.should eq({'Wellington' => 100})
      end
    end

    describe '#facet' do
      before(:each) do
        @search = Search.new
      end

      it 'returns the specified facet' do
        facet = Supplejack::Facet.new('collection', [])
        @search.stub(:facets) { [facet] }

        @search.facet('collection').should eq facet
      end

      it 'returns nil when facet is not found' do
         @search.stub(:facets) { [] }
         @search.facet('collection').should be_nil
      end

      it 'returns nil if value is nil' do
        facet = Supplejack::Facet.new('collection', [])
        @search.stub(:facets) { [facet] }
        @search.facet(nil).should be_nil
      end
    end

    describe '#total' do
      before(:each) do
        @search = Search.new
        @search.instance_variable_set(:@response, {'search' => {'result_count' => 100}})
      end

      it 'executes the request only once' do
        @search.should_receive(:execute_request).once
        @search.total
        @search.total
      end

      it 'returns the total from the response' do
        @search.total.should eq 100
      end

      it 'returns 0 when the request to the API failed' do
        @search.instance_variable_set(:@response, {'search' => {}})
        @search.total.should eq 0
      end
    end

    describe '#results' do
      before(:each) do
        Supplejack.stub(:record_klass).and_return('TestRecord')
        @search = Search.new
        @record1 = {'id' => 1, 'title' => 'Wellington'}
        @record2 = {'id' => 2, 'title' => 'Auckland'}
        @search.instance_variable_set(:@response, {'search' => {'results' => [@record1, @record2]}})
      end

      it 'executes the request only once' do
        @search.stub(:total) { 10 }
        @search.should_receive(:execute_request).once
        @search.results
        @search.results
      end

      it 'initializes record objects with the default class' do
        TestRecord.should_receive(:new).with(@record1)
        TestRecord.should_receive(:new).with(@record2)
        @search.results
      end

      it 'initializes record objects with the class provided in the params' do
        @search = Search.new(:record_klass => 'test_item')
        @search.instance_variable_set(:@response, {'search' => {'results' => [@record1, @record2]}})
        TestItem.should_receive(:new).with(@record1)
        TestItem.should_receive(:new).with(@record2)
        @search.results
      end

      it 'returns a array of objects of the provided class' do
        @search.results.first.class.should eq TestRecord
      end

      it 'returns an array wraped in paginated collection object' do
        @search.results.current_page.should eq 1
      end

      it 'returns empty paginated collection when API request failed' do
        @search.instance_variable_set(:@response, {'search' => {}})
        @search.results.size.should eq 0
      end
    end

    describe '#counts' do
      before(:each) do
        @search = Search.new
        @search.stub(:fetch_counts) { {'images' => 100} }
      end

      context 'caching disabled' do
        before(:each) do
          Supplejack.stub(:enable_caching) { false }
        end

        it 'fetches the counts' do
          query_params = {'images' => {:category => 'Images'}}
          @search.should_receive(:fetch_counts).with(query_params)
          @search.counts(query_params)
        end
      end
    end

    describe '#fetch_counts' do
      context 'without filters' do
        before(:each) do
          @search = Search.new
        end

        it 'returns a hash with row names and its values' do
          @search.stub(:get).and_return({'search' => {'facets' => {'counts' => {'images' => 151818}}}})
          @search.fetch_counts({}).should eq({'images' => 151818})
        end

        it 'returns every count even when there are no results matching' do
          @search.stub(:get).and_return({'search' => {'facets' => {'counts' => {'images' => 151818}}}})
          @search.fetch_counts({:images => {}, :headings => {}}).should eq({'images' => 151818, 'headings' => 0})
        end

        it 'returns 0 for every facet when the API response fails' do
          @search.stub(:get).and_raise(StandardError)
          @search.fetch_counts({:images => {}}).should eq({'images' => 0})
        end
      end
    end

    describe '#counts_params' do
      context 'without filters' do
        before(:each) do
          @search = Search.new
        end

        it 'requests record_type == all' do
          query_parameters = {:headings => {:record_type => '1'}}
          @search.counts_params(query_parameters).should include(:facet_query => query_parameters, :record_type => 'all')
        end

        it 'adds the restrictions set in the without variable' do
          query_parameters = {:headings => {:record_type => '1'}}
          @search.without = {:location => 'Wellington'}
          @search.counts_params(query_parameters).should include(:without => {:location => 'Wellington'})
        end

        it 'restricts the result set to only ones that match the and filters' do
          query_parameters = {:headings => {:record_type => '1'}}
          @search.and = {:location => 'Wellington'}
          @search.counts_params(query_parameters).should include(:and => {:location => 'Wellington'})
        end

        it 'restricts the result set to results that match any of the or filters' do
          query_parameters = {:headings => {:record_type => '1'}}
          @search.or = {:location => ['Wellington', 'Auckland']}
          @search.counts_params(query_parameters).should include(:or => {:location => ['Wellington', 'Auckland']})
        end

        it 'executes a request with facet_queries' do
          query_parameters = {:images => {:creator => 'all', :record_type => '0'}, :headings => {:record_type => '1'}}
          @search.counts_params(query_parameters).should include(:facet_query => query_parameters)
        end

        it 'passes the text when present' do
          @search = Search.new(:text => 'dogs')
          @search.counts_params({}).should include(:text => 'dogs')
        end

        # it 'passes the geo_bbox when present' do
        #   @search = Search.new(geo_bbox: '1,2,3,4')
        #   @search.counts_params({}).should include(geo_bbox: '1,2,3,4')
        # end

        it 'merges the :i and :il filters with record_type 0' do
          query_parameters = {:images => {'creator' => 'all', 'record_type' => '0'}, :headings => {'record_type' => '1', :dc_type => 'Group'}}
          @search = Search.new(:i => {:category => 'Images'}, :il => {:year => '1998'})

          images_query = {:creator => 'all', :record_type => '0', :category => 'Images', :year => '1998'}
          headings_query = {:record_type => '1', :dc_type => 'Group'}

          @search.counts_params(query_parameters).should include(:facet_query => {:images => images_query, :headings => headings_query})
        end

        it 'merges *_text fields' do
          query_parameters = {:images => {'creator' => 'all', 'record_type' => '0'}}
          @search = Search.new(:i => {:subject_text => 'dog'})

          images_query = {:creator => 'all', :record_type => '0'}

          @search.counts_params(query_parameters).should include(:text => 'dog', :query_fields => [:subject], :facet_query => {:images => images_query})
        end
      end

      context 'with active filters' do
        before(:each) do
          @search = Search.new(:i => {:location => 'Wellington'})
        end

        it 'merges the existing filters into every facet query' do
          query_parameters = {:images => {'creator' => 'all', 'record_type' => 0}}
          expected_filters = {:images => {:creator => 'all', :location => 'Wellington', :record_type => 0}}
          @search.counts_params(query_parameters).should include(:facet_query => expected_filters)
        end

        it 'merges existing filters without overriding' do
          query_parameters = {:images => {'location' => 'Matapihi', 'record_type' => 0}}
          expected_filters = {:images => {:location => ['Wellington', 'Matapihi'], :record_type => 0}}
          @search.counts_params(query_parameters).should include(:facet_query => expected_filters)
        end

        it 'overrides the record_type' do
          @search = Search.new(:record_type => '1')
          query_parameters = {:images => {'record_type' => '0'}}
          expected_filters = {:images => {:record_type => '0'}}
          @search.counts_params(query_parameters).should include(:facet_query => expected_filters)
        end
        
        it 'merges existing negative filters' do
          @search = Search.new(:i => {'-category' => 'Groups'})
          query_parameters = {:photos => {'has_large_thumbnail_url' => 'Y'}}
          expected_filters = {:photos => {:has_large_thumbnail_url => 'Y', :'-category' => 'Groups'}}
          @search.counts_params(query_parameters).should include(:facet_query => expected_filters)
        end
      end
    end

    describe '#request_path' do
      before(:each) do
        @search = Search.new
      end

      it 'returns /records by default' do
        @search.request_path.should eq '/records'
      end
    end

    describe '#execute_request' do
      before(:each) do
        @search = Search.new
      end

      it 'only executes the request once' do
        @search.should_receive(:get).once.and_return('{}')
        @search.execute_request
        @search.execute_request
      end

      it 'removes the results that match the without filters' do
        @search.without = {:location => 'Wellington'}
        @search.should_receive(:get).with('/records', hash_including(:without => {:location => 'Wellington'}))
        @search.execute_request
      end

      it 'restricts the result set to only ones that match the and filters' do
        @search.and = {:location => 'Wellington'}
        @search.should_receive(:get).with('/records', hash_including(:and => {:location => 'Wellington'}))
        @search.execute_request
      end

      it 'restricts the result set to only ones that match any of the or filters' do
        @search.or = {:location => ['Wellington']}
        @search.should_receive(:get).with('/records', hash_including(:or => {:location => ['Wellington']}))
        @search.execute_request
      end

      it 'returns a empty search hash when a error is raised' do
        @search.stub(:get).and_raise(StandardError)
        @search.execute_request.should eq({'search' => {}})
      end

      context 'caching enabled' do
        before :each do
          @cache = double(:cache).as_null_object
          Rails.stub(:cache) { @cache }
          Supplejack.stub(:enable_caching) { true }
        end

        it 'caches the response when it is cacheable' do
          search = Supplejack::Search.new
          search.stub(:cacheable?) { true }
          cache_key = Digest::MD5.hexdigest("/records?#{search.api_params.to_query}")
          Rails.cache.should_receive(:fetch).with(cache_key, expires_in: 1.hour)
          search.execute_request
        end

        it 'doesnt cache the response it is not cacheable' do
          search = Supplejack::Search.new(text: "dogs")
          search.stub(:cacheable?) { false }
          Rails.cache.should_not_receive(:fetch)
          search.execute_request
        end
      end
    end

    describe '#cacheable?' do
      it 'returns true when it doesn\'t have a text parameter' do
        Supplejack::Search.new.cacheable?.should be_true
      end

      it 'returns false when it has a text parameter' do
        Supplejack::Search.new(text: 'Dogs').cacheable?.should be_false
      end

      it 'returns false then it\'s not the first page of results' do
        Supplejack::Search.new(page: '2').cacheable?.should be_false
      end
    end

    describe '#has_attribute_name?' do
      before(:each) do
        @search = Search.new
        @search.location = ['Wellington', 'Auckland']
      end

      it 'returns true if value is in filter' do
        @search.has_location?('Wellington').should be_true
      end

      it 'returns false is value is not in filter' do
        @search.has_location?('Videos').should be_false
      end

      context 'search filter is single valued' do
        before(:each) do
          @search = Search.new
          @search.location = 'Wellington'
        end

        it 'returns true if value matches filter' do
          @search.has_location?('Wellington').should be_true
        end

        it 'returns false if value does not match the filter' do
          @search.has_location?('Cats').should be_false
        end

        it 'returns false when location has nil value' do
          @search.location = nil
          @search.has_category?('Cats').should be_false
        end

        it 'shouldn\'t search for a non existent search attribute' do
          Supplejack.stub(:search_attributes) { [] }
          @search.should_not_receive(:has_filter_and_value?)
          @search.has_category?('Cats')
        end
      end
    end

    describe '#categories' do
      before(:each) do
        @search = Search.new({:i => {:category => 'Books', :year => 2001}, :text => 'Dogs'})
        @search.stub(:get) { {'search' => {'facets' => {'category' => {'Books' => 123}}, 'result_count' => 123}} }
      end

      it 'should call the fetch_values method' do
        @search.should_receive(:facet_values).with('category', {})
        @search.categories
      end

      it 'removes category filter from the search request' do
        @search.should_receive(:get).with('/records', hash_including(:and => {:year => 2001})).and_return({'search' => {'facets' => {'category' => {'Books' => 123}}}})
        @search.categories
      end

      it 'returns the category facet hash ' do
        @search.categories.should include('Books' => 123)
      end

      it 'asks the API for 0 results' do
        @search.should_receive(:get).with('/records', hash_including({:per_page => 0}))
        @search.categories
      end

      it 'should return add the All count to the hash' do
        @search.categories['All'].should eq 123
      end

      it 'orders the category values by :count' do
        @search.should_receive(:facet_values).with('category', {:sort => :count})
        @search.categories({:sort => :count})
      end
    end

    describe '#fetch_facet_values' do
      before(:each) do
        @search = Search.new({:i => {:category => 'Books', :year => 2001}, :text => 'Dogs'})
        @search.stub(:get) { {'search' => {'facets' => {'category' => {'Books' => 123}}, 'result_count' => 123}} }
      end

      it 'returns the category facet hash' do
        @search.fetch_facet_values('category').should include('Books' => 123)
      end

      it 'returns empty values when the request to the API failed' do
        @search.stub(:get).and_raise(StandardError)
        @search.fetch_facet_values('category').should eq({'All' => 0})
      end

      it 'should add the All count to the hash' do
        @search.fetch_facet_values('category')['All'].should eq 123
      end

      it 'doesnt return the All count ' do
        @search.fetch_facet_values('category', {:all => false}).should_not have_key('All')
      end

      it 'memoizes the facet_values' do
        @search.should_receive(:get).once
        @search.fetch_facet_values('category')
        @search.fetch_facet_values('category')
      end

      context 'sorting' do
        before(:each) do
          @facet = Supplejack::Facet.new('category', {'All' => 123, 'Books' => 123})
          Supplejack::Facet.stub(:new) { @facet }
        end

        it 'initializes a Supplejack::Facet' do
          Supplejack::Facet.should_receive(:new).with('category', {'All' => 123, 'Books' => 123})
          @search.fetch_facet_values('category')
        end

        it 'tells the facet how to sort the values' do
          @facet.should_receive(:values).with(:index)
          @search.fetch_facet_values('category', {:sort => :index})
        end

        it 'doesn\'t sort by default' do
          @facet.should_receive(:values).with(nil)
          @search.fetch_facet_values('category')
        end
      end
    end

    describe 'facet_values_params' do
      before(:each) do
        @search = Search.new({:i => {:type => 'Person', :year => 2001}, :text => 'Dogs'})
      end

      it 'removes type filter from the search request' do
        @search.facet_values_params('type').should include(:and => {:year => 2001})
      end

      it 'requests 0 results per_page' do
        @search.facet_values_params('type').should include(:per_page => 0)
      end

      it 'adds without filters' do
        @search = Search.new({:i => {:type => 'Person', :year => 2001, '-group' => 'Group'}, :text => 'Dogs'})
        @search.facet_values_params('type').should include(:without => {:group => 'Group'})
      end

      it 'only adds the and_filters to :and' do
        @search = Search.new({:i => {:type => 'Person', :year => 2001, '-group' => 'Group'}, :text => 'Dogs'})
        @search.facet_values_params('type').should include(:and => {:year => 2001})
      end

      it 'gets the facet_values for a record_type 1' do
        @search = Search.new({:i => {:type => 'Person'}, :h => {:group => 'Group'}, :text => 'Dogs', :record_type => 1})
        @search.facet_values_params('group').should include(:and => {})
      end

      it 'restricts results to filters specified in without accessor' do
        @search = Search.new
        @search.without = {:website => 'Flickr'}
        @search.facet_values_params('type').should include(:without => {:website => 'Flickr'})
      end

      it 'merges in the filters specified in without' do
        @search = Search.new({:i => {'-type' => 'Person'}})
        @search.without = {:website => 'Flickr'}
        @search.facet_values_params('type').should include(:without => {:website => 'Flickr', :type => 'Person'})
      end

      it 'adds the restrictions set in the and variable' do
        @search = Search.new
        @search.and = {:content_partner => 'NLNZ'}
        @search.facet_values_params('type').should include(:and => {:content_partner => 'NLNZ'})
      end

      it 'adds the restrictions set in the or variable' do
        @search = Search.new
        @search.or = {:content_partner => 'NLNZ'}
        @search.facet_values_params('type').should include(:or => {:content_partner => 'NLNZ'})
      end

      it 'memoizes the params' do
        @search = Search.new
        @search.should_receive(:url_format).once.and_return(double(:url_format, :and_filters => {}))
        @search.facet_values_params('type')
        @search.facet_values_params('type')
      end

      it 'adds a parameter for facets_per_page if the option is present' do
         @search.facet_values_params('type', {:facets_per_page => 15}).should include(:facets_per_page => 15)
      end
    end

    describe '#facet_values' do
      before(:each) do
        @search = Search.new
        @search.stub(:fetch_facet_values) { {'Books' => 100} }
      end

      context 'caching disabled' do
        before(:each) do
          Supplejack.stub(:enable_caching) { false }
        end

        it 'fetches the facet values' do
          @search.should_receive(:fetch_facet_values).with('category', anything)
          @search.facet_values('category', anything)
        end
      end
    end

    describe '#merge_extra_filters' do
      before(:each) do
        @search = Search.new
      end

      it 'merges the and filters' do
        @search.and = {:type => 'Person'}
        @search.merge_extra_filters({:and => {:location => 'Wellington'}}).should eq({:and => {:location => 'Wellington', :type => 'Person'}})
      end

      it 'merges the or filters' do
        @search.or = {:type => 'Person'}
        @search.merge_extra_filters({:and => {:location => 'Wellington'}}).should eq({:and => {:location => 'Wellington'}, :or => {:type => 'Person'}})
      end

      it 'merges the without filters' do
        @search.without = {:type => 'Person'}
        @search.merge_extra_filters({:and => {:location => 'Wellington'}}).should eq({:and => {:location => 'Wellington'}, :without => {:type => 'Person'}})
      end
    end

  end
end