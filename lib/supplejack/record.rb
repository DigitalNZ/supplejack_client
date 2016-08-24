# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

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
        define_method("#{method}") do
          values = @attributes[method]
          values.is_a?(Array) ? values.first : values
        end
      end
    end

    def initialize(attributes={})
      if attributes.is_a?(String)
        attributes = JSON.parse(attributes) rescue {}
      end
      @attributes = attributes.symbolize_keys rescue {}
    end

    def id
      id = @attributes[:id] || @attributes[:record_id]
      id.to_i
    end

    def to_param
      self.id
    end

    def title
      @attributes[:title].present? ? @attributes[:title] : "Untitled"
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
          if @attributes.has_key?(field)
            values = @attributes[field]
            values ||= [] unless !!values == values # Testing if boolean
            values = [values] unless values.is_a?(Array)

            case fields[:format]
            when "uppercase" then field = field.to_s.upcase
            when "lowercase" then field = field.to_s.downcase
            when "camelcase" then field = field.to_s.camelcase
            end

            field = field.to_s.sub(/#{schema}_/, '')
            values.each do |value|
              metadata << {:name => field, :schema => schema.to_s, :value => value }
            end
          end          
        end
      end

      metadata
    end

    def format
      unless @attributes.has_key?(:format)
        raise NoMethodError, "undefined method 'format' for Supplejack::Record:Module" 
      end
      @attributes[:format]
    end

    [:next_page, :previous_page, :next_record, :previous_record].each do |pagination_field|
      define_method(pagination_field) do
        @attributes[pagination_field]
      end
    end

    def persisted?
      true
    end

    def method_missing(symbol, *args, &block)
      unless @attributes.has_key?(symbol)
        raise NoMethodError, "undefined method '#{symbol.to_s}' for Supplejack::Record:Module" 
      end
      @attributes[symbol]
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
      def find(id_or_array, options={})
        if id_or_array.is_a?(Array)
          options = {:record_ids => id_or_array, :fields => Supplejack.fields.join(',') }
          response = get("/records/multiple", options)
          response["records"].map {|attributes| new(attributes) }
        else
          begin
            # handle malformed id's before requesting anything. 
            id = id_or_array.to_i
            raise(Supplejack::MalformedRequest, "'#{id_or_array}' is not a valid record id") if id <= 0

            # Do not send any parameters in the :search key when the user didn't specify any options
            # And also always send the :fields parameter
            #
            search_klass = Supplejack::Search
            search_klass = Supplejack.search_klass.classify.constantize if Supplejack.search_klass.present?

            any_options = options.try(:any?)

            search = search_klass.new(options)
            search_options = search.api_params
            search_options = search.merge_extra_filters(search_options)

            options = {:search => search_options}
            options[:fields] = options[:search].delete(:fields)
            options.delete(:search) unless any_options

            response = get("/records/#{id}", options)
            new(response['record'])
          rescue RestClient::ResourceNotFound => e
            raise Supplejack::RecordNotFound, "Record with ID #{id_or_array} was not found"
          end
        end
      end
    end

  end
end
