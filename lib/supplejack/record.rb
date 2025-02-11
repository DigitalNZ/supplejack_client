# frozen_string_literal: true

require 'supplejack/search'

module Supplejack
  module Record
    extend ActiveSupport::Concern

    attr_accessor :attributes

    included do
      extend Supplejack::Request
      extend ActiveModel::Naming
      include ActiveModel::Conversion

      # Some of the records in the API return an array of values, but in practice
      # most of them have on only one value. What this does is just convert the array
      # to a string for the methods defined in the configuration.
      Supplejack.single_value_methods.each do |method|
        define_method(method.to_s) do
          values = @attributes[method]
          values.is_a?(Array) ? values.first : values
        end
      end
    end

    def initialize(attributes = {})
      if attributes.is_a?(String)
        attributes = begin
          JSON.parse(attributes)
        rescue StandardError
          {}
        end
      end

      @attributes = begin
        attributes.symbolize_keys
      rescue StandardError
        {}
      end
    end

    def id
      id = @attributes[:id] || @attributes[:record_id]
      id.to_i
    end

    def to_param
      id
    end

    def title
      @attributes[:title].presence || 'Untitled'
    end

    # Returns a array of hashes containing all the record attributes and
    # the schema each attribute belongs to. To set what fields belong to
    # each schema there is a config option to set supplejack_fields and admin_fields
    #
    # @example
    #   record.metadata => [{:name => "location", :schema => "supplejack", :value => "Wellington" }, ...]
    #
    def metadata
      metadata = []

      Supplejack.send('special_fields').each do |schema, fields|
        fields[:fields].each do |field|
          next unless @attributes.key?(field)

          values = @attributes[field]
          values ||= [] unless [true, false].include?(values)
          values = [values] unless values.is_a?(Array)

          case fields[:format]
          when 'uppercase' then field = field.to_s.upcase
          when 'lowercase' then field = field.to_s.downcase
          when 'camelcase' then field = field.to_s.camelcase
          end

          field = field.to_s.sub(/#{schema}_/, '')
          values.each do |value|
            metadata << { name: field, schema: schema.to_s, value: }
          end
        end
      end

      metadata
    end

    def format
      return @attributes[:format] if @attributes.key?(:format)

      raise NoMethodError, "undefined method 'format' for Supplejack::Record:Module"
    end

    %i[next_page previous_page next_record previous_record].each do |pagination_field|
      define_method(pagination_field) do
        @attributes[pagination_field]
      end
    end

    def persisted?
      true
    end

    def method_missing(symbol, *_args)
      return @attributes[symbol] if @attributes.key?(symbol)

      raise NoMethodError, "undefined method '#{symbol}' for Supplejack::Record:Module"
    end

    def respond_to_missing?(symbol, *_args)
      @attributes.key?(symbol)
    end

    module ClassMethods
      # Finds a record or array of records from the Supplejack API
      #
      # @params [ Integer, Array ] id A integer or array of integers representing the ID of records
      # @params [ Hash ] options Search options used to perform a search in order to get the next/previous
      #   records within the search results.
      #
      # @return [ Supplejack::Record ] A record or array of records initialized with the class of where the
      # Supplejack::Record module was included
      #
      def find(id_or_array, options = {})
        if id_or_array.is_a?(Array)
          options = { record_ids: id_or_array, fields: Supplejack.fields.join(',') }
          response = get('/records/multiple', options)
          response['records'].map { |attributes| new(attributes) }
        else
          begin
            # Do not send any parameters in the :search key when the user didn't specify any options
            # And also always send the :fields parameter
            #
            search_klass = Supplejack::Search
            search_klass = Supplejack.search_klass.classify.constantize if Supplejack.search_klass.present?

            any_options = options.try(:any?)

            search = search_klass.new(options)
            search_options = search.api_params
            search_options = search.merge_extra_filters(search_options)

            options = { search: search_options }
            options[:fields] = options[:search].delete(:fields)
            options.delete(:search) unless any_options

            response = get("/records/#{id_or_array}", options)
            new(response['record'])
          rescue RestClient::ResourceNotFound
            raise Supplejack::RecordNotFound, "Record with ID #{id_or_array} was not found"
          end
        end
      end
    end
  end
end
