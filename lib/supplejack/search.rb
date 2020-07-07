# frozen_string_literal: true

require 'supplejack/request'
require 'digest/md5'

module Supplejack
  # FIXME: make me smaller!
  class Search
    include Supplejack::Request

    attr_accessor :results, :text, :page, :per_page, :pagination_limit, :direction
    attr_accessor :sort, :filters, :record_type, :record_klass, :geo_bbox
    attr_accessor :url_format, :without, :and, :or, :params, :api_params

    def initialize(params = {})
      @params = begin
                  params.clone
                rescue StandardError
                  {}
                end
      @params[:facets] ||= Supplejack.facets.join(',')
      @params[:facets_per_page] ||= Supplejack.facets_per_page
      %i[action controller].each { |p| @params.delete(p) }

      @text             = @params[:text]
      @geo_bbox         = @params[:geo_bbox]
      @record_type      = @params[:record_type]
      @record_type      = @record_type.to_i unless @record_type == 'all'
      @page             = (@params[:page] || 1).to_i
      @per_page         = (@params[:per_page] || Supplejack.per_page).to_i
      @pagination_limit = @params[:pagination_limit] || Supplejack.pagination_limit
      @sort             = @params[:sort]
      @direction        = @params[:direction]
      @url_format       = Supplejack.url_format_klass.new(@params, self)
      @filters          = @url_format.filters
      @api_params       = @url_format.to_api_hash
      @record_klass     = @params[:record_klass] || Supplejack.record_klass

      # Do not execute the actual search right away, it should be lazy loaded
      # when the user needs one of the following values.
      @total    = nil
      @results  = nil
      @facets   = nil

      Supplejack.search_attributes.each do |attribute|
        # We have to define the attribute accessors for the filters at initialization of the search instance
        # otherwise because the rails initializer is run after the gem was loaded, only the default
        # Supplejack.search_attributes set in the Gem would be defined.

        self.class.send(:attr_accessor, attribute)
        send("#{attribute}=", @filters[attribute]) unless @filters[attribute] == 'all'
      end
    end

    # Returns by default a array of two element arrays with all the active filters
    # in the search object and their values
    #
    # @example Return a array of filters
    #   search = Search.new(:i => {:content_partner => "Matapihi", :category => ["Images", "Videos"]})
    #   search.filters => [[:content_partner, "Matapihi"], [:category, "Images"], [:category, "Videos"]]
    #
    # @return [ Array<Array> ] Array with two element arrays, each with the filter and its value.
    #
    def filters(options = {})
      options.reverse_merge!(format: :array, except: [])
      return @filters if options[:format] == :hash

      filters = []
      @filters.each do |key, value|
        unless options[:except].include?(key)
          if value.is_a?(Array)
            value.each do |v|
              filters << [key, v]
            end
          else
            filters << [key, value]
          end
        end
      end

      filters
    end

    def options(filter_options = {})
      @url_format.options(filter_options)
    end

    # Returns an array of facets for the current search criteria sorted by
    # the order specified in +Supplejack.facets+
    #
    # @example facets return format
    #   search.facets => [Supplejack::Facet]
    #
    # @param [ Hash ] options Supported options: :drill_dates
    #
    # @return [ Array<Supplejack::Facet> ] Every element in the array is a Supplejack::Facet object,
    # and responds to name and values
    #
    def facets(_options = {})
      return @facets if @facets

      execute_request

      facets = @response['search']['facets'] || {}

      facet_array = facets.sort_by { |facet, _rows| Supplejack.facets.find_index(facet.to_sym) || 100 }
      @facets = facet_array.map { |name, values| Supplejack::Facet.new(name, values) }
    end

    def facet(value)
      facets.find { |facet| facet.name == value }
    end

    def facet_pivots
      execute_request

      facet_pivots = @response['search']['facet_pivots'] || {}

      facet_array = facet_pivots.sort_by { |facet, _rows| Supplejack.facets.find_index(facet.to_sym) || 100 }
      facet_array.map { |name, values| Supplejack::Facet.new(name, values) }
    end

    # Returns a array of +Supplejack::Record+ objects wrapped in a Paginated Collection
    # which provides methods for will_paginate and kaminari to work properly
    #
    # It will initialize the +Supplejack::Record+ objects with the class stored in
    # +Supplejack.record_klass+, so that you can override any method provided by the +Supplejack::Record+
    # module or create new methods. You can also provide a +:record_klass+ option
    # when initialing a +Supplejack::Search+ object to override the record_klass on a per request basis.
    #
    # @return [ Array ] Array of +Supplejack::Record+ objects
    #
    def results
      return @results if @results

      execute_request

      records = if @response['search']['results'].respond_to?(:map)
                  @response['search']['results'].map do |attributes|
                    @record_klass.classify.constantize.new(attributes)
                  end
                else
                  []
                end

      last_page = [pagination_limit || total, total].min
      @results = Supplejack::PaginatedCollection.new(records, page, per_page, last_page)
    end

    # Returns the total amount of records for the current search filters
    #
    # @returns [ Integer ] Number of records that match the current search criteria
    #
    def total
      return @total if @total

      execute_request
      @total = @response['search']['result_count'].to_i
    end

    def record?
      record_type == 0
    end

    # Calculates counts for specific queries using solr's facet.query
    #
    # @example Request images with a large_thumbnail_url and of record_type = 1:
    #   search.counts({"photos" => {:large_thumbnail_url => "all", :record_type => 1}})
    # @example Returns the following hash:
    #   {"photos" => 100}
    #
    # @param [Hash{String => Hash{String => String}}] a hash with query names as keys and a hash with filters as values.
    # @return [Hash{String => Integer}] A hash with the query names as keys and the result count for every query as values
    def counts(query_parameters = {})
      if Supplejack.enable_caching
        cache_key = Digest::MD5.hexdigest(counts_params(query_parameters).to_query)
        Rails.cache.fetch(cache_key, expires_in: 1.day) do
          fetch_counts(query_parameters)
        end
      else
        fetch_counts(query_parameters)
      end
    end

    def fetch_counts(query_parameters = {})
      begin
        response = get(request_path, counts_params(query_parameters))
        counts_hash = response['search']['facets']['counts']
      rescue StandardError
        counts_hash = {}
      end

      # When the search doesn't match any facets for the specified filters, Sunspot doesn't return any facets
      # at all. Here we add those keys with a value of 0.
      #
      query_parameters.each_pair do |count_name, _count_filters|
        counts_hash[count_name.to_s] = 0 unless counts_hash[count_name.to_s]
      end

      counts_hash
    end

    # Returns a hash with all the parameters required by the counts method
    #
    def counts_params(query_parameters = {})
      query_with_filters = {}
      query_parameters.each_pair do |count_name, count_filters|
        count_filters = count_filters.symbolize_keys
        query_record_type = count_filters[:record_type].to_i
        type = query_record_type == 0 ? :items : :headings
        filters = url_format.and_filters(type).dup

        without_filters = url_format.without_filters(type).dup
        without_filters = Hash[without_filters.map { |key, value| ["-#{key}".to_sym, value] }]

        filters.merge!(without_filters)
        query_with_filters.merge!(count_name.to_sym => Supplejack::Util.deep_merge(filters, count_filters))
      end

      params = { facet_query: query_with_filters, record_type: 'all' }
      params[:text] = url_format.text
      params[:text] = text if text.present?
      params[:geo_bbox] = geo_bbox if geo_bbox.present?
      params[:query_fields] = url_format.query_fields
      params = merge_extra_filters(params)
      params
    end

    # Gets the type facet unrestricted by the current type filter
    #
    # @return [Hash{String => Integer}] A hash of type names and counts
    #
    def categories(options = {})
      return @categories if @categories

      @categories = facet_values('category', options)
    end

    # Gets the facet values unrestricted by the current filter
    #
    # @return [Hash{String => Integer}] A hash of facet names and counts
    #
    def fetch_facet_values(facet_name, options = {})
      options.reverse_merge!(all: true, sort: nil)
      memoized_values = instance_variable_get("@#{facet_name}_values")
      return memoized_values if memoized_values

      begin
        response = get(request_path, facet_values_params(facet_name, options))
        @facet_values = response['search']['facets'][facet_name.to_s]
      rescue StandardError
        # rubocop:disable Lint/UselessAssignment
        response = { 'search' => { 'result_count' => 0 } }
        # rubocop:enable Lint/UselessAssignment
        @facet_values = {}
      end

      @facet_values['All'] = @facet_values.values.sum if options[:all]

      facet = Supplejack::Facet.new(facet_name, @facet_values)
      @facet_values = facet.values(options[:sort])

      instance_variable_set("@#{facet_name}_values", @facet_values)
      @facet_values
    end

    # Returns a hash with all the parameters required by the facet_values
    # method
    #
    def facet_values_params(facet_name, options = {})
      memoized_values = instance_variable_get("@#{facet_name}_params")
      return memoized_values if memoized_values

      filters = url_format.and_filters
      filters.delete(facet_name.to_sym)

      facet_params = api_params
      facet_params[:and] = filters
      facet_params[:facets] = facet_name.to_s
      facet_params[:per_page] = 0
      facet_params[:facets_per_page] = options[:facets_per_page] if options[:facets_per_page]
      facet_params[:facet_pivots] = options[:facet_pivots] if options[:facet_pivots]

      facet_params = merge_extra_filters(facet_params)

      instance_variable_set("@#{facet_name}_params", facet_params)
      facet_params
    end

    def facet_values(facet_name, options = {})
      if Supplejack.enable_caching
        cache_key = Digest::MD5.hexdigest(facet_values_params(facet_name).to_query)
        Rails.cache.fetch(cache_key, expires_in: 1.day) do
          fetch_facet_values(facet_name, options)
        end
      else
        fetch_facet_values(facet_name, options)
      end
    end

    def request_path
      '/records'
    end

    def execute_request
      return @response if @response

      @api_params = merge_extra_filters(@api_params)

      begin
        if Supplejack.enable_caching && cacheable?
          cache_key = Digest::MD5.hexdigest("#{request_path}?#{@api_params.to_query}")
          @response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
            get(request_path, @api_params)
          end
        else
          @response = get(request_path, @api_params)
        end
      rescue RestClient::ServiceUnavailable
        raise Supplejack::ApiNotAvailable, 'API is not responding'
      rescue RestClient::RequestTimeout, RestClient::Exceptions::ReadTimeout
        raise Supplejack::RequestTimeout, 'API call has timedout'
      rescue StandardError
        @response = { 'search' => {} }
      end
    end

    def cacheable?
      !(text.present? || page > 1)
    end

    # Gets the category facet unrestricted by the current category filter
    #
    # @return [Hash{String => Integer}] A hash of category names and counts
    #
    def categories(options = {})
      return @categories if @categories

      @categories = facet_values('category', options)
    end

    # Convienence method to find out if the search object has any specific filter
    # applied to it. It works for both single and multiple value filters.
    # This methods are actually defined on method_missing.
    #
    # @exampe Return true when the search has a category filter set to images
    #   search = Search.new(:i => {:category => ["Images"]})
    #   search.has_category?("Images") => true

    def has_filter_and_value?(filter, value)
      actual_value = *send(filter)
      return false unless actual_value

      actual_value.include?(value)
    end

    def method_missing(symbol, *args)
      if symbol.to_s.match(/has_(.+)\?/) && Supplejack.search_attributes.include?(Regexp.last_match(1).to_sym)
        has_filter_and_value?(Regexp.last_match(1), args.first)
      end
    end

    # Adds any filters defined in the :or, :and or :without attr_accessors
    # By setting them directly it allows to nest any conditions that is not
    # normally possible though the item_hash URL format.
    #
    def merge_extra_filters(existing_filters)
      and_filters = self.and.try(:any?) ? { and: self.and } : {}
      or_filters = self.or.try(:any?) ? { or: self.or } : {}
      without_filters = without.try(:any?) ? { without: without } : {}
      extra_filters = and_filters.merge(or_filters).merge(without_filters)

      Util.deep_merge(existing_filters, extra_filters)
    end
  end
end
