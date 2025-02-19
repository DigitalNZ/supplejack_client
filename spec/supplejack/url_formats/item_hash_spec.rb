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
          expect(item_hash(text: '').to_api_hash).not_to have_key(:text)
        end

        it 'returns the text in the params' do
          expect(item_hash(text: 'dog').to_api_hash).to include(text: 'dog')
        end

        it 'returns the geo_bbox in the params' do
          expect(item_hash(geo_bbox: '1,2,3,4').to_api_hash).to include(geo_bbox: '1,2,3,4')
        end

        it 'type casts the record_type' do
          expect(item_hash(record_type: '1').to_api_hash).to include(record_type: 1)
        end

        it 'returns by default page 1' do
          expect(item_hash.to_api_hash).to include(page: 1)
        end

        it 'returns the page parameter' do
          expect(item_hash(page: '3').to_api_hash).to include(page: 3)
        end

        it 'returns the per_page set in the initializer' do
          allow(Supplejack).to receive(:per_page).and_return(15)

          expect(item_hash.to_api_hash).to include(per_page: 15)
        end

        it 'returns the per_page in the parameters' do
          expect(item_hash(per_page: '22').to_api_hash).to include(per_page: 22)
        end

        it 'returns the and_filters in the :and key' do
          expect(item_hash(i: { description: 'Weird one' }).to_api_hash).to include(and: { description: 'Weird one' })
        end

        it 'returns the without_filters in the :without key' do
          expect(item_hash(i: { '-description' => 'Weird one' }).to_api_hash).to include(without: { description: 'Weird one' })
        end

        it 'returns the facets' do
          expect(item_hash(facets: 'description,creator').to_api_hash).to include(facets: 'description,creator')
        end

        it 'returns the facets page' do
          expect(item_hash(facets_page: '12').to_api_hash).to include(facets_page: 12)
        end

        it 'returns the facets per page' do
          expect(item_hash(facets_per_page: '12').to_api_hash).to include(facets_per_page: 12)
        end

        it 'returns the sort and direction' do
          expect(item_hash(sort: 'title', direction: 'desc').to_api_hash).to include(sort: 'title', direction: 'desc')
        end

        it 'doesn\'t return either sort nor direction when sort not present' do
          expect(item_hash(direction: 'desc').to_api_hash).not_to include(direction: 'desc')
        end

        it 'returns default direction "asc"' do
          expect(item_hash(sort: 'title').to_api_hash).to include(direction: 'asc')
        end

        it 'returns the default set of fields from config' do
          allow(Supplejack).to receive(:fields).and_return(%i[default atl])

          expect(item_hash.to_api_hash).to include(fields: 'default,atl')
        end

        it 'overrides the fields from the parameters' do
          expect(item_hash(fields: 'verbose,authorities').to_api_hash).to include(fields: 'verbose,authorities')
        end

        it 'doesn\'t break when nil options hash' do
          expect(item_hash(nil).to_api_hash).to be_a Hash
        end

        it 'sends the solr_query option to the api' do
          expect(item_hash(solr_query: 'dc_type:Images').to_api_hash).to include(solr_query: 'dc_type:Images')
        end

        it 'sends no solr_query if empty' do
          expect(item_hash(solr_query: '').to_api_hash).not_to have_key(:solr_query)
        end
      end

      describe '#and_filters' do
        it 'returns every filter' do
          expect(item_hash(i: { 'sample_filter' => 'Groups' }).and_filters).to eq(sample_filter: 'Groups')
        end

        it 'skips restricted filter' do
          expect(item_hash(i: { 'sample_filter' => 'Groups', '-content_partner' => 'nlnz' }).and_filters).to eq(sample_filter: 'Groups')
        end

        it 'removes any _text filters' do
          expect(item_hash(i: { 'filter_with_text' => 'dog' }).and_filters).to eq({})
        end

        it 'returns only item filters if filter_type is :items' do
          expect(item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' }, record_type: 1).and_filters(:items)).to eq(subject: 'dog')
        end

        it 'returns only headings filters if filter_type is :headings' do
          expect(item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' }, record_type: 0).and_filters(:headings)).to eq(heading_type: 'record_type')
        end

        it 'memoizes :i and :h filters seperatly' do
          hash = item_hash(i: { 'subject' => 'dog' }, h: { 'heading_type' => 'record_type' })

          expect(hash.and_filters(:items)).to eq(subject: 'dog')
          expect(hash.and_filters(:headings)).to eq(heading_type: 'record_type')
        end
      end

      describe '#text_field?' do
        it 'returns true when the passed field is text' do
          expect(item_hash.text_field?('title_text')).to be true
        end

        it 'returns false when the passed field is not text' do
          expect(item_hash.text_field?('title_authority')).to be false
        end

        it 'returns false when the passed field is nil' do
          expect(item_hash.text_field?(nil)).to be false
        end
      end

      describe '#without_filters' do
        it 'returns only negative filters' do
          expect(item_hash(i: { '-negative_category' => 'Groups', 'positive_category' => 'nlnz' }).without_filters).to eq(negative_category: 'Groups')
        end

        it 'returns only item filters if filter_type is :items' do
          expect(item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' }, record_type: 1).without_filters(:items)).to eq(subject: 'dog')
        end

        it 'returns only headings filters if filter_type is :headings' do
          expect(item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' }, record_type: 0).without_filters(:headings)).to eq(heading_type: 'record_type')
        end

        it 'memoizes :i and :h filters seperatly' do
          hash = item_hash(i: { '-subject' => 'dog' }, h: { '-heading_type' => 'record_type' })

          expect(hash.without_filters(:items)).to eq(subject: 'dog')
          expect(hash.without_filters(:headings)).to eq(heading_type: 'record_type')
        end
      end

      describe '#text' do
        it 'returns the text if present' do
          expect(item_hash.text('dog')).to eq 'dog'
        end

        it 'returns nil when text is not present' do
          expect(item_hash.text('')).to be_nil
        end

        it 'extracts the text from name_text' do
          expect(item_hash(i: { name_text: 'john' }).text).to eq 'john'
        end
      end

      describe '#query_fields' do
        it 'returns all fields that end with _text' do
          expect(item_hash(i: { name_text: 'john', location_text: 'New Zealand' }).query_fields).to include(:name, :location)
        end

        it 'returns nil when no filters match _text' do
          expect(item_hash(i: { sample_collection: 'nlnz' }).query_fields).to be_nil
        end

        it 'returns only _text filters' do
          expect(item_hash(i: { name_text: 'john', sample_collection: 'nlnz' }).query_fields).to eq [:name]
        end
      end

      describe '#filters' do
        context 'with default records' do
          it 'returns the hash within the :i key and symbolizes them' do
            expect(item_hash(i: { 'location' => 'NZ' }).filters).to eq(location: 'NZ')
          end

          it 'merges in the locked filters' do
            result = { location: 'NZ', category: 'Images' }
            expect(item_hash(i: { 'location' => 'NZ' }, il: { 'category' => 'Images' }).filters).to eq(result)
          end

          it 'returns :h filters with record_type parameter' do
            expect(item_hash(i: { 'location' => 'NZ' }, h: { dc_type: 'Names' }).filters(:headings)).to eq(dc_type: 'Names')
          end

          it 'memoizes the :i and :h filters separately' do
            test_hash = item_hash(i: { 'location' => 'NZ' }, h: { dc_type: 'Names' })

            expect(test_hash.filters).to eq(location: 'NZ')
            expect(test_hash.filters(:headings)).to eq(dc_type: 'Names')
          end

          it 'handles a string in the :i hash' do
            expect(item_hash(i: '').filters.empty?).to be true
          end

          it 'handles a string in the :il hash' do
            expect(item_hash(il: '').filters.empty?).to be true
          end
        end

        context 'with headings tab' do
          it 'returns the hash within the :h key' do
            expect(item_hash(h: { 'heading_type' => 'Name' }, record_type: '1').filters).to eq(heading_type: 'Name')
          end

          it 'merges in the locked filters' do
            result = { heading_type: 'Name', year: '1900' }
            expect(item_hash(h: { 'heading_type' => 'Name' }, hl: { 'year' => '1900' }, record_type: '1').filters).to eq(result)
          end
        end
      end

      describe '#filter_symbol' do
        context 'when filter_type is nil' do
          it 'returns "i" when record_type is 0' do
            expect(item_hash(record_type: 0).filter_symbol).to eq 'i'
          end

          it 'returns "h" when record_type is 1' do
            expect(item_hash(record_type: 1).filter_symbol).to eq 'h'
          end
        end

        context 'when filter_type is provided' do
          it 'returns "i" when filter_type is :items' do
            expect(item_hash(record_type: 1).filter_symbol(:items)).to eq 'i'
          end

          it 'returns "h" when filter_type is :headings' do
            expect(item_hash(record_type: 0).filter_symbol(:headings)).to eq 'h'
          end
        end
      end

      describe '#filters_of_type' do
        it 'returns item unlocked filters' do
          expect(item_hash(i: { category: 'Images' }).filters_of_type(:i)).to eq(category: 'Images')
        end
      end

      describe '#options' do
        let(:search) { Supplejack::Search.new }

        it 'returns a hash with the search parameters' do
          params = { i: { name: 'John' }, il: { type: 'Person' }, h: { heading_type: 'Name' }, hl: { year: '1900' } }
          expect(item_hash(params, search).options).to eq params
        end

        it 'doesnt return any empty values' do
          expect(item_hash({ i: { name: '', type: nil, location: 'Wellington' } }, search).options).to eq(i: { location: 'Wellington' })
        end

        it 'returns a empty hash when filters are empty' do
          expect(item_hash({ i: { name: '', type: nil } }, search).options).to eq({})
        end

        it 'doesn\'t return page parameter when page 1' do
          expect(item_hash({ page: 1 }, search).options).to eq({})
        end

        it 'doesn\'t return page parameter is empty' do
          expect(item_hash({}, search).options).to eq({})
        end

        it 'removes the filters in the :except parameter' do
          expect(item_hash({ i: { name: 'John' }, il: { type: 'Person' } }, search).options(except: [:name])).to eq(il: { type: 'Person' })
        end

        it 'includes the record_type when is 1' do
          search = Supplejack::Search.new(record_type: 1)
          expect(item_hash({ record_type: 1 }, search).options).to include(record_type: 1)
        end

        it 'excludes the page parameter' do
          search = Supplejack::Search.new(page: 3)
          expect(item_hash({}, search).options(except: [:page])).not_to include(page: 3)
        end

        it 'adds multiple values to the same facet' do
          search = Supplejack::Search.new(i: { name: 'John' })
          expect(item_hash({ i: { name: 'John' } }, search).options(plus: { i: { name: 'James' } })[:i]).to include(name: %w[John James])
        end

        it 'removes one value from the same 2 facet' do
          search = Supplejack::Search.new(i: { name: %w[John James] })

          expect(item_hash({ i: { name: %w[John James] } }, search).options(except: [{ name: 'James' }])[:i]).to include(name: 'John')
        end

        it 'removes one value from the same 3 facet' do
          search = Supplejack::Search.new(i: { name: %w[John James Jake] })

          expect(item_hash({ i: { name: %w[John James Jake] } }, search).options(except: [{ name: 'James' }])[:i]).to include(name: %w[John Jake])
        end

        it 'removes the whole facet if there is no remaining values' do
          params = { i: { name: %w[John James], type: 'Person' } }
          search = Supplejack::Search.new(params)
          expect(item_hash(params, search).options(except: [{ name: %w[James John] }])[:i]).not_to have_key(:name)
        end

        context 'when in the items tab' do
          it 'merges filters in the :plus parameter to the unlocked hash' do
            expect(item_hash({}, search).options(plus: { i: { 'type' => 'Something' } })[:i]).to include(type: 'Something')
          end
        end
      end
    end
  end
end
