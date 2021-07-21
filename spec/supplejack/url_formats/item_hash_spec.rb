# frozen_string_literal: true

require 'spec_helper'

def item_hash(params = {}, search = nil)
  Supplejack::UrlFormats::ItemHash.new(params, search)
end

module Supplejack
  module UrlFormats
    describe ItemHash do
      describe '#to_api_hash' do
        it 'doesn\'t return blank text' do
          item_hash(text: '').to_api_hash.should_not have_key(:text)
        end

        it 'returns the text in the params' do
          item_hash(text: 'dog').to_api_hash.should include(text: 'dog')
        end

        it 'returns the geo_bbox in the params' do
          item_hash(geo_bbox: '1,2,3,4').to_api_hash.should include(geo_bbox: '1,2,3,4')
        end

        it 'type casts the record_type' do
          item_hash(record_type: '1').to_api_hash.should include(record_type: 1)
        end

        it 'returns by default page 1' do
          item_hash.to_api_hash.should include(page: 1)
        end

        it 'returns the page parameter' do
          item_hash(page: '3').to_api_hash.should include(page: 3)
        end

        it 'returns the per_page set in the initializer' do
          Supplejack.stub(:per_page) { 15 }
          item_hash.to_api_hash.should include(per_page: 15)
        end

        it 'returns the per_page in the parameters' do
          item_hash(per_page: '22').to_api_hash.should include(per_page: 22)
        end

        it 'returns the and_filters in the :and key' do
          item_hash(i: { description: 'Weird one' }).to_api_hash.should include(and: { description: 'Weird one' })
        end

        it 'returns the without_filters in the :without key' do
          item_hash(i: { '-description' => 'Weird one' }).to_api_hash.should include(without: { description: 'Weird one' })
        end

        it 'returns the facets' do
          item_hash(facets: 'description,creator').to_api_hash.should include(facets: 'description,creator')
        end

        it 'returns the facets per page' do
          item_hash(facets_per_page: '12').to_api_hash.should include(facets_per_page: 12)
        end

        it 'returns the sort and direction' do
          item_hash(sort: 'title', direction: 'desc').to_api_hash.should include(sort: 'title', direction: 'desc')
        end

        it 'doesn\'t return either sort nor direction when sort not present' do
          item_hash(direction: 'desc').to_api_hash.should_not include(direction: 'desc')
        end

        it 'returns default direction "asc"' do
          item_hash(sort: 'title').to_api_hash.should include(direction: 'asc')
        end

        it 'returns the default set of fields from config' do
          Supplejack.stub(:fields) { %i[default atl] }
          item_hash.to_api_hash.should include(fields: 'default,atl')
        end

        it 'overrides the fields from the parameters' do
          item_hash(fields: 'verbose,authorities').to_api_hash.should include(fields: 'verbose,authorities')
        end

        it 'doesn\'t break when nil options hash' do
          item_hash(nil).to_api_hash.should be_a Hash
        end

        it 'sends the solr_query option to the api' do
          item_hash(solr_query: 'dc_type:Images').to_api_hash.should include(solr_query: 'dc_type:Images')
        end

        it 'shouldn\'t send the solr_query if empty' do
          item_hash(solr_query: '').to_api_hash.should_not have_key(:solr_query)
        end

        # it 'adds query_fields to the hash if present' do
        #   convert(@search, {:i => {:creator_text => 'john'}}).should include(:query_fields => [:creator])
        # end
        #
        # it 'doesn't add empty query fields' do
        #   convert(@search, {:i => {:display_collection => 'nzlnz'}}).should_not have_key(:query_fields)
        # end
      end

      describe '#and_filters' do
        it 'returns every filter' do
          item_hash(i: { 'sample_filter' => 'Groups' }).and_filters.should eq(sample_filter: 'Groups')
        end

        it 'returns every filter' do
          item_hash(i: { 'sample_filter' => 'Groups', '-content_partner' => 'nlnz' }).and_filters.should eq(sample_filter: 'Groups')
        end

        it 'removes any _text filters' do
          item_hash(i: { 'filter_with_text' => 'dog' }).and_filters.should eq({})
        end

        it 'returns only item filters if filter_type is :items' do
          item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' }, record_type: 1).and_filters(:items).should eq(subject: 'dog')
        end

        it 'returns only headings filters if filter_type is :headings' do
          item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' }, record_type: 0).and_filters(:headings).should eq(heading_type: 'record_type')
        end

        it 'memoizes :i and :h filters seperatly' do
          hash = item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' })
          hash.and_filters(:items).should eq(subject: 'dog')
          hash.and_filters(:headings).should eq(heading_type: 'record_type')
        end
      end

      describe '#text_field?' do
        it 'returns true when the passed field is text' do
          item_hash.text_field?('title_text').should be_truthy
        end

        it 'returns false when the passed field is not text' do
          item_hash.text_field?('title_authority').should be_falsey
        end

        it 'returns false when the passed field is nil' do
          item_hash.text_field?(nil).should be_falsey
        end
      end

      describe '#without_filters' do
        it 'returns only negative filters' do
          item_hash(i: { '-negative_category' => 'Groups', 'positive_category' => 'nlnz' }).without_filters.should eq(negative_category: 'Groups')
        end

        it 'returns only item filters if filter_type is :items' do
          item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' }, record_type: 1).without_filters(:items).should eq(subject: 'dog')
        end

        it 'returns only headings filters if filter_type is :headings' do
          item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' }, record_type: 0).without_filters(:headings).should eq(heading_type: 'record_type')
        end

        it 'memoizes :i and :h filters seperatly' do
          hash = item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' })
          hash.without_filters(:items).should eq(subject: 'dog')
          hash.without_filters(:headings).should eq(heading_type: 'record_type')
        end
      end

      describe '#text' do
        it 'returns the text if present' do
          item_hash.text('dog').should eq 'dog'
        end

        it 'returns nil when text is not present' do
          item_hash.text('').should be_nil
        end

        it 'extracts the text from name_text' do
          item_hash(i: { name_text: 'john' }).text.should eq 'john'
        end
      end

      describe '#query_fields' do
        it 'returns all fields that end with _text' do
          item_hash(i: { name_text: 'john', location_text: 'New Zealand' }).query_fields.should include(:name, :location)
        end

        it 'returns nil when no filters match _text' do
          item_hash(i: { sample_collection: 'nlnz' }).query_fields.should be_nil
        end

        it 'returns only _text filters' do
          item_hash(i: { name_text: 'john', sample_collection: 'nlnz' }).query_fields.should eq [:name]
        end
      end

      describe '#filters' do
        context 'default records' do
          it 'returns the hash within the :i key and symbolizes them' do
            item_hash(i: { 'location' => 'NZ' }).filters.should eq(location: 'NZ')
          end

          it 'merges in the locked filters' do
            result = { location: 'NZ', category: 'Images' }
            item_hash(i: { 'location' => 'NZ' }, il: { 'category' => 'Images' }).filters.should eq(result)
          end

          it 'returns :h filters with record_type parameter' do
            item_hash(i: { 'location' => 'NZ' }, h: { dc_type: 'Names' }).filters(:headings).should eq(dc_type: 'Names')
          end

          it 'memoizes the :i and :h filters separately' do
            @hash = item_hash(i: { 'location' => 'NZ' }, h: { dc_type: 'Names' })
            @hash.filters.should eq(location: 'NZ')
            @hash.filters(:headings).should eq(dc_type: 'Names')
          end

          it 'handles a string in the :i hash' do
            item_hash(i: '').filters.should be_empty
          end

          it 'handles a string in the :il hash' do
            item_hash(il: '').filters.should be_empty
          end
        end

        context 'headings tab' do
          it 'returns the hash within the :h key' do
            item_hash(h: { 'heading_type' => 'Name' }, record_type: '1').filters.should eq(heading_type: 'Name')
          end

          it 'merges in the locked filters' do
            result = { heading_type: 'Name', year: '1900' }
            item_hash(h: { 'heading_type' => 'Name' }, hl: { 'year' => '1900' }, record_type: '1').filters.should eq(result)
          end
        end
      end

      describe '#filter_symbol' do
        context 'when filter_type is nil' do
          it 'returns "i" when record_type is 0' do
            item_hash(record_type: 0).filter_symbol.should eq 'i'
          end

          it 'returns "h" when record_type is 1' do
            item_hash(record_type: 1).filter_symbol.should eq 'h'
          end
        end

        context 'filter_type is provided' do
          it 'returns "i" when filter_type is :items' do
            item_hash(record_type: 1).filter_symbol(:items).should eq 'i'
          end

          it 'returns "h" when filter_type is :headings' do
            item_hash(record_type: 0).filter_symbol(:headings).should eq 'h'
          end
        end
      end

      describe '#filters_of_type' do
        it 'returns item unlocked filters' do
          item_hash(i: { category: 'Images' }).filters_of_type(:i).should eq(category: 'Images')
        end
      end

      describe '#options' do
        before(:each) do
          @search = Supplejack::Search.new
        end

        it 'returns a hash with the search parameters' do
          params = { i: { name: 'John' }, il: { type: 'Person' }, h: { heading_type: 'Name' }, hl: { year: '1900' } }
          item_hash(params, @search).options.should eq params
        end

        it 'doesnt return any empty values' do
          item_hash({ i: { name: '', type: nil, location: 'Wellington' } }, @search).options.should eq(i: { location: 'Wellington' })
        end

        it 'returns a empty hash when filters are empty' do
          item_hash({ i: { name: '', type: nil } }, @search).options.should eq({})
        end

        it 'doesn\'t return page parameter when page 1' do
          item_hash({ page: 1 }, @search).options.should eq({})
        end

        it 'doesn\'t return page parameter is empty' do
          item_hash({}, @search).options.should eq({})
        end

        it 'removes the filters in the :except parameter' do
          item_hash({ i: { name: 'John' }, il: { type: 'Person' } }, @search).options(except: [:name]).should eq(il: { type: 'Person' })
        end

        it 'includes the record_type when is 1' do
          search = Supplejack::Search.new(record_type: 1)
          item_hash({ record_type: 1 }, search).options.should include(record_type: 1)
        end

        it 'excludes the page parameter' do
          search = Supplejack::Search.new(page: 3)
          item_hash({}, search).options(except: [:page]).should_not include(page: 3)
        end

        it 'adds multiple values to the same facet' do
          search = Supplejack::Search.new(i: { name: 'John' })
          item_hash({ i: { name: 'John' } }, search).options(plus: { i: { name: 'James' } })[:i].should include(name: %w[John James])
        end

        it 'only removes one value from the same facet' do
          search = Supplejack::Search.new(i: { name: %w[John James] })
          item_hash({ i: { name: %w[John James] } }, search).options(except: [{ name: 'James' }])[:i].should include(name: 'John')
        end

        it 'only removes one value from the same facet' do
          search = Supplejack::Search.new(i: { name: %w[John James Jake] })
          item_hash({ i: { name: %w[John James Jake] } }, search).options(except: [{ name: 'James' }])[:i].should include(name: %w[John Jake])
        end

        it 'removes the whole facet if there is no remaining values' do
          params = { i: { name: %w[John James], type: 'Person' } }
          search = Supplejack::Search.new(params)
          item_hash(params, search).options(except: [{ name: %w[James John] }])[:i].should_not have_key(:name)
        end

        context 'in the items tab' do
          it 'merges filters in the :plus parameter to the unlocked hash' do
            item_hash({}, @search).options(plus: { i: { 'type' => 'Something' } })[:i].should include(type: 'Something')
          end
        end
      end
    end
  end
end
