# frozen_string_literal: true

require 'supplejack/search'

module Supplejack
  module Concept
    extend ActiveSupport::Concern
    include Supplejack::Request

    attr_accessor :attributes

    included do
      extend Supplejack::Request
      extend ActiveModel::Naming
      include ActiveModel::Conversion
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
      id = @attributes[:id] || @attributes[:concept_id]
      id.to_i
    end

    def to_param
      id
    end

    def name
      @attributes[:name].presence || 'Unknown'
    end

    %i[next_page previous_page next_concept previous_concept].each do |pagination_field|
      define_method(pagination_field) do
        @attributes[pagination_field]
      end
    end

    def persisted?
      true
    end

    def method_missing(symbol, *_args)
      unless @attributes.key?(symbol)
        raise NoMethodError, "undefined method '#{symbol}' for Supplejack::Concept:Module"
      end

      @attributes[symbol]
    end

    module ClassMethods
      # Finds a record or array of records from the Supplejack API
      #
      # @params [ Integer ] id an integer representing the id of a concept
      # @params [ Hash ] options Search options used to perform a search in order to get the next/previous
      #   concepts within the search results.
      #
      # @return [ Supplejack::Concept ] A concept initialized with the class of where the
      # Supplejack::Concept module was included
      #
      def find(id, options = {})
        # handle malformed id's before requesting anything.
        id = id.to_i
        raise(Supplejack::MalformedRequest, "'#{id}' is not a valid concept id") if id <= 0

        # This will not work until the Concepts API supports groups properly
        # options = options.merge({fields: 'default'})

        response = get("/concepts/#{id}", options)
        new(response)
      rescue RestClient::ResourceNotFound
        raise Supplejack::ConceptNotFound, "Concept with ID #{id} was not found"
      end

      def all(options = {})
        get('/concepts', options)
      end
    end
  end
end
