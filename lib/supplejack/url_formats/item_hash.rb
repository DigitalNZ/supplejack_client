
module Supplejack
  module UrlFormats
    class ItemHash

      attr_accessor :params, :search, :i_unlocked, :i_locked, :h_unlocked, :h_locked

      def initialize(params={}, search=nil)
        @params     = params || {}
        @search     = search
        @i_unlocked = filters_of_type(:i)
        @i_locked   = filters_of_type(:il)
        @h_unlocked = filters_of_type(:h)
        @h_locked   = filters_of_type(:hl)
      end

      def to_api_hash
        hash = {}
        text_value = text(params[:text])
        hash[:text]             = text_value if text_value
        hash[:geo_bbox]         = params[:geo_bbox] if params[:geo_bbox]
        hash[:record_type]      = params[:record_type] || 0
        hash[:record_type]      = hash[:record_type].to_i unless hash[:record_type]=="all"
        hash[:page]             = (params[:page] || 1).to_i
        hash[:per_page]         = (params[:per_page] || Supplejack.per_page).to_i
        hash[:and]              = and_filters if and_filters.try(:any?)
        hash[:without]          = without_filters if without_filters.try(:any?)
        hash[:facets]           = params[:facets] if params[:facets].present?
        hash[:facets_per_page]  = params[:facets_per_page].to_i if params[:facets_per_page].present?
        hash[:fields]           = params[:fields] || Supplejack.fields.join(',')
        hash[:query_fields]     = query_fields if query_fields
        hash[:solr_query]       = params[:solr_query] if params[:solr_query].present?
        hash[:ignore_metrics]   = params[:ignore_metrics] if params[:ignore_metrics].present?
        hash[:exclude_filters_from_facets]   = params[:exclude_filters_from_facets] || false

        if params[:sort].present?
          hash[:sort] = params[:sort]
          hash[:direction] = params[:direction] || "asc"
        end

        hash
      end

      # Returns all the active filters for the current search
      # These filters are used to scope the search results
      #
      def filters(filter_type=nil)
        filters = {}

        symbol = filter_symbol(filter_type)

        memoized_filters = self.instance_variable_get("@#{symbol}_filters")
        return memoized_filters if memoized_filters

        unlocked = filters_of_type(symbol.to_sym)
        locked = filters_of_type("#{symbol}l".to_sym)

        filters = Supplejack::Util.deep_merge!(unlocked, locked)

        @all_filters = filters.dup.symbolize_keys.to_hash rescue {}
        self.instance_variable_set("@#{symbol}_filters", @all_filters)
        @all_filters
      end

      def and_filters(filter_type=nil)
        @and_filters ||= {}
        valid_filters = filters(filter_type).reject {|filter, value| filter.to_s.match(/-(.+)/)}
                                            .reject {|filter, value| is_text_field?(filter)}
        @and_filters[filter_symbol(filter_type)] ||= valid_filters
      end

      def is_text_field?(filter)
        return false if filter.nil? || Supplejack.non_text_fields.include?(filter.to_sym)
        filter.to_s.split(//).last(5).join('').to_s == '_text'
      end

      def without_filters(filter_type=nil)
        symbol = filter_symbol(filter_type)
        @without_filters ||= {}
        return @without_filters[symbol] if @without_filters[symbol]

        @without_filters[symbol] = {}
        filters(filter_type).each_pair do |filter, value|
          if filter.to_s.match(/-(.+)/)
            @without_filters[symbol][$1.to_sym] = value
          end
        end
        @without_filters[symbol]
      end

      def all_filters
        return @all_filters if @all_filters
        self.filters
        @all_filters
      end

      def filter_symbol(filter_type=nil)
        if filter_type
          filter_type == :items ? 'i' : 'h'
        else
          params[:record_type].to_i == 0 ? 'i' : 'h'
        end
      end

      # Returns the value from the text param and joins any values from
      # fields which end in _text (ie. creator_text)
      #
      # @param [ String ] default_text A string with the user query
      #
      def text(default_text=nil)
        text_values = []
        text_values << default_text if default_text.present?

        all_filters.each do |filter, value|
          text_values << value if is_text_field?(filter)
        end

        return nil if text_values.empty?
        text_values.join(' ')
      end

      # Returns the query_fields from the current search filters so that
      # specific fields can be searched.
      # The '_text' is removed from the end of the field name
      #
      def query_fields
        query_fields = []

        all_filters.each do |filter, value|
          if is_text_field?(filter)
            query_fields << filter.to_s.chomp!('_text').to_sym
          end
        end

        return nil if query_fields.empty?
        query_fields
      end

      # Returns one type of filters
      #
      # @param [ :i, :il, :h, :hl ] filter_type The symbol of the filter type
      #
      def filters_of_type(filter_type)
        params[filter_type].dup.symbolize_keys.to_hash rescue {}
      end

      # Returns a hash options to be used for generating URL's with all the search state.
      #
      # @param [ Hash ] filter_options A hash of options to be able to remove or add filters
      #
      # @filter_option option [ Array ] :except A array of filter names to be removed
      # @filter_options option [ Hash ] :plus A hash with filters and their values to be added
      #
      # rubocop:disable Metrics/MethodLength
      # FIXME: make me smaller!
      def options(filter_options={})
        filter_options.reverse_merge!({:except => [], :plus => {}})
        filter_options[:except] ||= []

        hash = {}
        {:i => :i_unlocked, :il => :i_locked, :h => :h_unlocked, :hl => :h_locked}.each_pair do |symbol, instance_name|
          filters = self.send(instance_name).clone || {}

          filters.each_pair do |name, value|
            filters.delete(name) if value.blank?
          end

          filter_options[:except].each do |exception|
            if exception.is_a?(Hash)
              facet, values_to_delete = exception.first
              values_to_delete = Util.array(values_to_delete)
              existing_values = Util.array(filters[facet])
              new_values = existing_values - values_to_delete

              if new_values.any?
                new_values = new_values.first if new_values.size == 1
                filters[facet] = new_values
              else
                filters.delete(facet)
              end
            else
              filters.delete(exception)
            end
          end

          if filter_options[:plus].try(:any?) && filter_options[:plus][symbol].try(:any?)
            filters = Util.deep_merge(filters, filter_options[:plus][symbol])
          end

          hash[symbol] = filters.symbolize_keys if filters.any?
        end

        [:text, :direction, :sort].each do |attribute|
          attribute_value = search.send(attribute)
          hash.merge!(attribute => attribute_value) if attribute_value.present?
        end

        unless filter_options[:except].include?(:page)
          hash.merge!(:page => search.page) if search.page.present? && search.page != 1
        end

        hash.merge!(:record_type => 1) if search.record_type > 0
        return hash
      end
      # rubocop:enable Metrics/MethodLength

    end
  end
end
