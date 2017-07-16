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
  module Concept
    extend ActiveSupport::Concern
    include Supplejack::Request

    attr_accessor :attributes

    included do
      extend Supplejack::Request
      extend ActiveModel::Naming
      include ActiveModel::Conversion
    end

    def initialize(attributes={})
      if attributes.is_a?(String)
        attributes = JSON.parse(attributes) rescue {}
      end
      @attributes = attributes.symbolize_keys rescue {}
    end

    def id
      id = @attributes[:id] || @attributes[:concept_id]
      id.to_i
    end

    def to_param
      self.id
    end

    def name
      @attributes[:name].present? ? @attributes[:name] : "Unknown"
    end

    [:next_page, :previous_page, :next_concept, :previous_concept].each do |pagination_field|
      define_method(pagination_field) do
        @attributes[pagination_field]
      end
    end

    def persisted?
      true
    end

    def method_missing(symbol, *args, &block)
      unless @attributes.has_key?(symbol)
        raise NoMethodError, "undefined method '#{symbol.to_s}' for Supplejack::Concept:Module"
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
      def find(id, options={})
        begin
          # handle malformed id's before requesting anything.
          id = id.to_i
          raise(Supplejack::MalformedRequest, "'#{id}' is not a valid concept id") if id <= 0

          # This will not work until the Concepts API supports groups properly
          #options = options.merge({fields: 'default'})

          response = get("/concepts/#{id}", options)
          new(response)
        rescue RestClient::ResourceNotFound => e
          raise Supplejack::ConceptNotFound, "Concept with ID #{id} was not found"
        end
      end

      def all
        get('/concepts.json')
      end

    end
  end
end
