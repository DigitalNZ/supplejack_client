# frozen_string_literal: true

require 'spec_helper'

class TestRecord
  def initialize(attributes = {}) end
end

class TestItem
  def initialize(attributes = {}) end
end

module Supplejack
  describe Search do
    describe '#params' do
      it 'defaults to facets set in initializer' do
        allow(Supplejack).to receive(:facets).and_return(%w[location description])

        expect(described_class.new.api_params[:facets]).to eq('location,description')
      end

      it 'sets the facets through the params' do
        expect(described_class.new(facets: 'name,description').api_params[:facets]).to eq('name,description')
      end

      it 'defaults to facets_per_page set in initializer' do
        allow(Supplejack).to receive(:facets_per_page).and_return(33)

        expect(described_class.new.api_params[:facets_per_page]).to eq 33
      end

      it 'sets the facets_per_page through the params' do
        expect(described_class.new(facets_per_page: 13).api_params[:facets_per_page]).to eq 13
      end

      it 'deletes rails specific params' do
        params = described_class.new(controller: 'records', action: 'index').api_params

        expect(params).not_to have_key(:controller)
        expect(params).not_to have_key(:action)
      end
    end

    describe '#text' do
      it 'returns the search text' do
        expect(described_class.new(text: 'dog').text).to eq('dog')
      end
    end

    describe '#page' do
      it 'defaults to 1' do
        expect(described_class.new.page).to eq 1
      end

      it 'converts the page to a number' do
        expect(described_class.new(page: '2').page).to eq 2
      end
    end

    describe '#per_page' do
      it 'defaults to the per_page in the initializer' do
        allow(Supplejack).to receive(:per_page).and_return(16)

        expect(described_class.new.per_page).to eq 16
      end

      it 'sers the per_page through the params' do
        expect(described_class.new(per_page: '3').per_page).to eq 3
      end
    end

    describe '#sort' do
      it 'returns the field to sort on' do
        expect(described_class.new(sort: 'content_partner').sort).to eq 'content_partner'
      end

      it 'returns nil when not set' do
        expect(described_class.new.sort).to be nil
      end
    end

    describe '#direction' do
      it 'returns the direction to sort the results' do
        expect(described_class.new(direction: 'asc').direction).to eq 'asc'
      end

      it 'returns nil when not set' do
        expect(described_class.new.direction).to be nil
      end
    end

    describe '#search_attributes' do
      it 'sets the filter defined in Supplejack.search_attributes with its current value' do
        allow(Supplejack).to receive(:search_attributes).and_return([:location])

        expect(described_class.new(i: { location: 'Wellington' }).location).to eq 'Wellington'
      end
    end

    describe '#filters' do
      let(:filters) { { location: 'Wellington', country: 'New Zealand' } }

      it 'returns filters in a array format by default' do
        expect(described_class.new(i: filters).filters).to include([:location, 'Wellington'], [:country, 'New Zealand'])
      end

      it 'returns a hash of the current search filters' do
        expect(described_class.new(i: filters).filters(format: :hash)).to include(filters)
      end

      it 'expands filters that contain arrays' do
        filters = { location: %w[Wellington Auckland] }
        expect(described_class.new(i: filters).filters).to include([:location, 'Wellington'], [:location, 'Auckland'])
      end

      it 'removes the location filter' do
        filters = { location: %w[Wellington Auckland] }
        expect(described_class.new(i: filters).filters(except: [:location])).not_to include([:location, 'Wellington'], [:location, 'Auckland'])
      end
    end

    describe '#facets' do
      let(:search) { described_class.new }
      let(:facets_hash) { { 'location' => { 'Wellington' => 100 }, 'mayor' => { 'Brake, Brian' => 20 } } }

      before do
        Supplejack.facets = [:location]
        search.instance_variable_set(:@response, 'search' => { 'facets' => facets_hash })
      end

      it 'executes the request only once' do
        expect(search).to receive(:execute_request).once

        search.facets
        search.facets
      end

      it 'handles a failed request from the API' do
        search.instance_variable_set(:@response, 'search' => {})
        expect(search.facets.empty?).to be true
      end

      it 'initializes a facet object for each facet' do
        expect(Supplejack::Facet).to receive(:new).with('location', 'Wellington' => 100)
        expect(Supplejack::Facet).to receive(:new).with('mayor', 'Brake, Brian' => 20)

        search.facets
      end

      it 'orders the facets based on the order set in the initializer' do
        allow(Supplejack).to receive(:facets).and_return(%i[mayor location])

        expect(search.facets.first.name).to eq 'mayor'
        expect(search.facets.last.name).to eq 'location'
      end

      it 'orders the facets the other way around' do
        allow(Supplejack).to receive(:facets).and_return(%i[location mayor])

        expect(search.facets.first.name).to eq 'location'
        expect(search.facets.last.name).to eq 'mayor'
      end

      it 'returns the facet values' do
        expect(search.facets.first.values).to eq('Wellington' => 100)
      end
    end

    describe '#facet' do
      let(:search) { described_class.new }

      it 'returns the specified facet' do
        facet = Supplejack::Facet.new('collection', [])
        allow(search).to receive(:facets) { [facet] }

        expect(search.facet('collection')).to eq facet
      end

      it 'returns nil when facet is not found' do
        allow(search).to receive(:facets).and_return([])

        expect(search.facet('collection')).to be nil
      end

      it 'returns nil if value is nil' do
        facet = Supplejack::Facet.new('collection', [])
        allow(search).to receive(:facets) { [facet] }

        expect(search.facet(nil)).to be nil
      end
    end

    describe '#facet_pivots' do
      let(:search) { described_class.new }

      it 'returns empty array when there are no facet pivots' do
        search.instance_variable_set(:@response, 'search' => {})

        expect(search.facet_pivots).to eq []
      end

      it 'returns empty array when there are empty facet pivots' do
        search.instance_variable_set(:@response, 'search' => { 'facet_pivots' => {} })

        expect(search.facet_pivots).to eq []
      end

      it 'returns facet_pivots correct when there are facet pivots' do
        search.instance_variable_set(
          :@response,
          'search' => { facet_pivots: { 'display_collection_s' => [{ 'field' => 'display_collection_s', 'value' => 'Auckland Libraries Heritage Images Collection', 'count' => 26 }] } }
        )

        expect(search.facet_pivots).not_to eq []
      end
    end

    describe '#total' do
      let(:search) { described_class.new }

      before { search.instance_variable_set(:@response, 'search' => { 'result_count' => 100 }) }

      it 'executes the request only once' do
        expect(search).to receive(:execute_request).once
        search.total
        search.total
      end

      it 'returns the total from the response' do
        expect(search.total).to eq 100
      end

      it 'returns 0 when the request to the API failed' do
        search.instance_variable_set(:@response, 'search' => {})

        expect(search.total).to eq 0
      end
    end

    describe '#results' do
      let(:search)  { described_class.new }
      let(:record1) { { 'id' => 1, 'title' => 'Wellington' } }
      let(:record2) { { 'id' => 2, 'title' => 'Auckland' } }

      before do
        allow(Supplejack).to receive(:record_klass).and_return('TestRecord')
        search.instance_variable_set(:@response, 'search' => { 'results' => [record1, record2] })
      end

      it 'executes the request only once' do
        allow(search).to receive(:total).and_return(10)

        expect(search).to receive(:execute_request).once

        search.results
        search.results
      end

      it 'initializes record objects with the default class' do
        expect(TestRecord).to receive(:new).with(record1)
        expect(TestRecord).to receive(:new).with(record2)

        search.results
      end

      it 'initializes record objects with the class provided in the params' do
        search = described_class.new(record_klass: 'test_item')
        search.instance_variable_set(:@response, 'search' => { 'results' => [record1, record2] })

        expect(TestItem).to receive(:new).with(record1)
        expect(TestItem).to receive(:new).with(record2)

        search.results
      end

      it 'returns a array of objects of the provided class' do
        expect(search.results.first.class).to eq TestRecord
      end

      it 'returns an array wraped in paginated collection object' do
        expect(search.results.current_page).to eq 1
      end

      it 'returns empty paginated collection when API request failed' do
        search.instance_variable_set(:@response, 'search' => {})

        expect(search.results.size).to eq 0
      end
    end

    describe '#counts' do
      let(:search) { described_class.new }

      before { allow(search).to receive(:fetch_counts).and_return({ 'images' => 100 }) }

      context 'when caching is disabled' do
        before { allow(Supplejack).to receive(:enable_caching).and_return(false) }

        it 'fetches the counts' do
          query_params = { 'images' => { category: 'Images' } }

          expect(search).to receive(:fetch_counts).with(query_params)

          search.counts(query_params)
        end
      end
    end

    describe '#fetch_counts' do
      context 'without filters' do
        let(:search) { described_class.new }

        it 'returns a hash with row names and its values' do
          allow(search).to receive(:get).and_return('search' => { 'facets' => { 'counts' => { 'images' => 151_818 } } })

          expect(search.fetch_counts({})).to eq('images' => 151_818)
        end

        it 'returns every count even when there are no results matching' do
          allow(search).to receive(:get).and_return('search' => { 'facets' => { 'counts' => { 'images' => 151_818 } } })

          expect(search.fetch_counts(images: {}, headings: {})).to eq('images' => 151_818, 'headings' => 0)
        end

        it 'returns 0 for every facet when the API response fails' do
          allow(search).to receive(:get).and_raise(StandardError)

          expect(search.fetch_counts(images: {})).to eq('images' => 0)
        end
      end
    end

    describe '#counts_params' do
      context 'without filters' do
        let(:search) { described_class.new }

        it 'requests record_type == all' do
          query_parameters = { headings: { record_type: '1' } }

          expect(search.counts_params(query_parameters)).to include(facet_query: query_parameters, record_type: 'all')
        end

        it 'adds the restrictions set in the without variable' do
          query_parameters = { headings: { record_type: '1' } }
          search.without = { location: 'Wellington' }

          expect(search.counts_params(query_parameters)).to include(without: { location: 'Wellington' })
        end

        it 'restricts the result set to only ones that match the and filters' do
          query_parameters = { headings: { record_type: '1' } }
          search.and = { location: 'Wellington' }

          expect(search.counts_params(query_parameters)).to include(and: { location: 'Wellington' })
        end

        it 'restricts the result set to results that match any of the or filters' do
          query_parameters = { headings: { record_type: '1' } }
          search.or = { location: %w[Wellington Auckland] }

          expect(search.counts_params(query_parameters)).to include(or: { location: %w[Wellington Auckland] })
        end

        it 'executes a request with facet_queries' do
          query_parameters = { images: { creator: 'all', record_type: '0' }, headings: { record_type: '1' } }

          expect(search.counts_params(query_parameters)).to include(facet_query: query_parameters)
        end

        it 'passes the text when present' do
          search = described_class.new(text: 'dogs')

          expect(search.counts_params({})).to include(text: 'dogs')
        end

        it 'merges the :i and :il filters with record_type 0' do
          query_parameters = { images: { 'creator' => 'all', 'record_type' => '0' }, headings: { 'record_type' => '1', :dc_type => 'Group' } }
          search = described_class.new(i: { category: 'Images' }, il: { year: '1998' })

          images_query = { creator: 'all', record_type: '0', category: 'Images', year: '1998' }
          headings_query = { record_type: '1', dc_type: 'Group' }

          expect(search.counts_params(query_parameters)).to include(facet_query: { images: images_query, headings: headings_query })
        end

        it 'merges *_text fields' do
          query_parameters = { images: { 'creator' => 'all', 'record_type' => '0' } }
          search = described_class.new(i: { subject_text: 'dog' })

          images_query = { creator: 'all', record_type: '0' }

          expect(search.counts_params(query_parameters)).to include(text: 'dog', query_fields: [:subject], facet_query: { images: images_query })
        end
      end

      context 'with active filters' do
        let(:search) { described_class.new(i: { location: 'Wellington' }) }

        it 'merges the existing filters into every facet query' do
          query_parameters = { images: { 'creator' => 'all', 'record_type' => 0 } }
          expected_filters = { images: { creator: 'all', location: 'Wellington', record_type: 0 } }

          expect(search.counts_params(query_parameters)).to include(facet_query: expected_filters)
        end

        it 'merges existing filters without overriding' do
          query_parameters = { images: { 'location' => 'Matapihi', 'record_type' => 0 } }
          expected_filters = { images: { location: %w[Wellington Matapihi], record_type: 0 } }

          expect(search.counts_params(query_parameters)).to include(facet_query: expected_filters)
        end

        it 'overrides the record_type' do
          search = described_class.new(record_type: '1')
          query_parameters = { images: { 'record_type' => '0' } }
          expected_filters = { images: { record_type: '0' } }

          expect(search.counts_params(query_parameters)).to include(facet_query: expected_filters)
        end

        it 'merges existing negative filters' do
          search = described_class.new(i: { '-category' => 'Groups' })
          query_parameters = { photos: { 'has_large_thumbnail_url' => 'Y' } }
          expected_filters = { photos: { has_large_thumbnail_url: 'Y', '-category'.to_sym => 'Groups' } }

          expect(search.counts_params(query_parameters)).to include(facet_query: expected_filters)
        end

        it 'adds per_page params if present' do
          search = described_class.new(per_page: 0)

          expect(search.counts_params({})).to include(per_page: 0)
        end
      end
    end

    describe '#request_path' do
      let(:search) { described_class.new }

      it 'returns /records by default' do
        expect(search.request_path).to eq '/records'
      end
    end

    describe '#execute_request' do
      let(:search) { described_class.new }

      it 'only executes the request once' do
        expect(search).to receive(:get).once.and_return('{}')

        search.execute_request
        search.execute_request
      end

      it 'removes the results that match the without filters' do
        search.without = { location: 'Wellington' }

        expect(search).to receive(:get).with('/records', hash_including(without: { location: 'Wellington' }))

        search.execute_request
      end

      it 'restricts the result set to only ones that match the and filters' do
        search.and = { location: 'Wellington' }

        expect(search).to receive(:get).with('/records', hash_including(and: { location: 'Wellington' }))

        search.execute_request
      end

      it 'restricts the result set to only ones that match any of the or filters' do
        search.or = { location: ['Wellington'] }

        expect(search).to receive(:get).with('/records', hash_including(or: { location: ['Wellington'] }))

        search.execute_request
      end

      it 'returns a empty search hash when a error is raised' do
        allow(search).to receive(:get).and_raise(StandardError)

        expect(search.execute_request).to eq('search' => {})
      end

      context 'when api returns and error' do
        it 'raises a timeout error' do
          allow(search).to receive(:get).and_raise(RestClient::Exceptions::ReadTimeout)

          expect { search.execute_request }.to raise_error(Supplejack::RequestTimeout)
        end

        it 'raises a unavailable error' do
          allow(search).to receive(:get).and_raise(RestClient::ServiceUnavailable)

          expect { search.execute_request }.to raise_error(Supplejack::ApiNotAvailable)
        end

        it 'raises no error but returns an empty search' do
          allow(search).to receive(:get).and_raise(StandardError)

          expect(search.execute_request).to eq('search' => {})
        end
      end

      context 'when caching is enabled' do
        let(:cache) { instance_double(ActiveSupport::Cache::Store).as_null_object }

        before do
          allow(Rails).to receive(:cache) { cache }
          allow(Supplejack).to receive(:enable_caching).and_return(true)
        end

        it 'caches the response when it is cacheable' do
          search = described_class.new
          allow(search).to receive(:cacheable?).and_return(true)
          cache_key = Digest::MD5.hexdigest("/records?#{search.api_params.to_query}")

          expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.hour)

          search.execute_request
        end

        it 'doesnt cache the response it is not cacheable' do
          search = described_class.new(text: 'dogs')
          allow(search).to receive(:cacheable?).and_return(false)
          expect(Rails.cache).not_to receive(:fetch)

          search.execute_request
        end
      end
    end

    describe '#cacheable?' do
      it 'returns true when it doesn\'t have a text parameter' do
        expect(described_class.new.cacheable?).to be true
      end

      it 'returns false when it has a text parameter' do
        expect(described_class.new(text: 'Dogs').cacheable?).to be false
      end

      it 'returns false then it\'s not the first page of results' do
        expect(described_class.new(page: '2').cacheable?).to be false
      end
    end

    describe '#has_attribute_name?' do
      let(:search) { described_class.new }

      before { search.location = %w[Wellington Auckland] }

      it 'returns true if value is in filter' do
        expect(search.has_location?('Wellington')).to be true
      end

      it 'returns false is value is not in filter' do
        expect(search.has_location?('Videos')).to be false
      end

      context 'when search filter is single valued' do
        let(:search) { described_class.new }

        before { search.location = 'Wellington' }

        it 'returns true if value matches filter' do
          expect(search.has_location?('Wellington')).to be true
        end

        it 'returns false if value does not match the filter' do
          expect(search.has_location?('Cats')).to be false
        end

        it 'returns false when location has nil value' do
          search.location = nil

          expect(search.has_category?('Cats')).to be nil
        end

        it 'search for onlu existent search attribute' do
          allow(Supplejack).to receive(:search_attributes).and_return([])

          expect(search).not_to receive(:filter_and_value?)
          search.has_category?('Cats')
        end
      end
    end

    describe '#categories' do
      let(:search) { described_class.new(i: { category: 'Books', year: 2001 }, text: 'Dogs') }

      before do
        allow(search).to receive(:get).and_return({ 'search' => { 'facets' => { 'category' => { 'Books' => 123 } }, 'result_count' => 123 } })
      end

      it 'calls the fetch_values method' do
        expect(search).to receive(:facet_values).with('category', {})

        search.categories
      end

      it 'removes category filter from the search request' do
        allow(search).to receive(:get).with('/records', hash_including(and: { year: 2001 })).and_return('search' => { 'facets' => { 'category' => { 'Books' => 123 } } })

        search.categories
      end

      it 'returns the category facet hash ' do
        expect(search.categories).to include('Books' => 123)
      end

      it 'asks the API for 0 results' do
        expect(search).to receive(:get).with('/records', hash_including(per_page: 0))

        search.categories
      end

      it 'returns add the All count to the hash' do
        expect(search.categories['All']).to eq 123
      end

      it 'orders the category values by :count' do
        expect(search).to receive(:facet_values).with('category', sort: :count)

        search.categories(sort: :count)
      end
    end

    describe '#fetch_facet_values' do
      let(:search) { described_class.new(i: { category: 'Books', year: 2001 }, text: 'Dogs') }

      before do
        allow(search).to receive(:get).and_return({ 'search' => { 'facets' => { 'category' => { 'Books' => 123, 'Images' => 100 } }, 'result_count' => 123 } })
      end

      it 'returns the category facet hash' do
        expect(search.fetch_facet_values('category')).to include('Books' => 123)
      end

      it 'returns empty values when the request to the API failed' do
        allow(search).to receive(:get).and_raise(StandardError)

        expect(search.fetch_facet_values('category')).to eq('All' => 0)
      end

      it 'adds the All count to the hash with the sum of all facets' do
        expect(search.fetch_facet_values('category')['All']).to eq 223
      end

      it 'doesnt return the All count ' do
        expect(search.fetch_facet_values('category', all: false)).not_to have_key('All')
      end

      it 'memoizes the facet_values' do
        expect(search).to receive(:get).once

        search.fetch_facet_values('category')
        search.fetch_facet_values('category')
      end

      context 'when sorting' do
        before do
          @facet = Supplejack::Facet.new('category', 'All' => 223, 'Books' => 123, 'Images' => 100)
          allow(Supplejack::Facet).to receive(:new) { @facet }
        end

        it 'initializes a Supplejack::Facet' do
          expect(Supplejack::Facet).to receive(:new).with('category', 'All' => 223, 'Books' => 123, 'Images' => 100)

          search.fetch_facet_values('category')
        end

        it 'tells the facet how to sort the values' do
          expect(@facet).to receive(:values).with(:index)

          search.fetch_facet_values('category', sort: :index)
        end

        it 'doesn\'t sort by default' do
          expect(@facet).to receive(:values).with(nil)

          search.fetch_facet_values('category')
        end
      end
    end

    describe 'facet_values_params' do
      let(:search) { described_class.new(i: { type: 'Person', year: 2001 }, text: 'Dogs') }

      it 'removes type filter from the search request' do
        expect(search.facet_values_params('type')).to include(and: { year: 2001 })
      end

      it 'requests 0 results per_page' do
        expect(search.facet_values_params('type')).to include(per_page: 0)
      end

      it 'adds without filters' do
        search = described_class.new(i: { :type => 'Person', :year => 2001, '-group' => 'Group' }, text: 'Dogs')

        expect(search.facet_values_params('type')).to include(without: { group: 'Group' })
      end

      it 'only adds the and_filters to :and' do
        search = described_class.new(i: { :type => 'Person', :year => 2001, '-group' => 'Group' }, text: 'Dogs')

        expect(search.facet_values_params('type')).to include(and: { year: 2001 })
      end

      it 'gets the facet_values for a record_type 1' do
        search = described_class.new(i: { type: 'Person' }, h: { group: 'Group' }, text: 'Dogs', record_type: 1)

        expect(search.facet_values_params('group')).to include(and: {})
      end

      it 'restricts results to filters specified in without accessor' do
        search = described_class.new
        search.without = { website: 'Flickr' }

        expect(search.facet_values_params('type')).to include(without: { website: 'Flickr' })
      end

      it 'merges in the filters specified in without' do
        search = described_class.new(i: { '-type' => 'Person' })
        search.without = { website: 'Flickr' }

        expect(search.facet_values_params('type')).to include(without: { website: 'Flickr', type: 'Person' })
      end

      it 'adds the restrictions set in the and variable' do
        search = described_class.new
        search.and = { content_partner: 'NLNZ' }

        expect(search.facet_values_params('type')).to include(and: { content_partner: 'NLNZ' })
      end

      it 'adds the restrictions set in the or variable' do
        search = described_class.new
        search.or = { content_partner: 'NLNZ' }

        expect(search.facet_values_params('type')).to include(or: { content_partner: 'NLNZ' })
      end

      it 'memoizes the params' do
        search = described_class.new
        expect(search).to receive(:url_format).once.and_return(instance_double(Supplejack::UrlFormats::ItemHash, and_filters: {}))

        search.facet_values_params('type')
        search.facet_values_params('type')
      end

      it 'adds a parameter for facets_per_page if the option is present' do
        expect(search.facet_values_params('type', facets_per_page: 15)).to include(facets_per_page: 15)
      end
    end

    describe '#facet_values' do
      let(:search) { described_class.new }

      before { allow(search).to receive(:fetch_facet_values).and_return({ 'Books' => 100 }) }

      context 'when caching is disabled' do
        before { allow(Supplejack).to receive(:enable_caching).and_return(false) }

        it 'fetches the facet values' do
          expect(search).to receive(:fetch_facet_values).with('category', anything)

          search.facet_values('category', anything)
        end
      end
    end

    describe '#merge_extra_filters' do
      let(:search) { described_class.new }

      it 'merges the and filters' do
        search.and = { type: 'Person' }

        expect(search.merge_extra_filters(and: { location: 'Wellington' })).to eq(and: { location: 'Wellington', type: 'Person' })
      end

      it 'merges the or filters' do
        search.or = { type: 'Person' }

        expect(search.merge_extra_filters(and: { location: 'Wellington' })).to eq(and: { location: 'Wellington' }, or: { type: 'Person' })
      end

      it 'merges the without filters' do
        search.without = { type: 'Person' }

        expect(search.merge_extra_filters(and: { location: 'Wellington' })).to eq(and: { location: 'Wellington' }, without: { type: 'Person' })
      end
    end
  end
end
