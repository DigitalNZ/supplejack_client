# frozen_string_literal: true

module Supplejack
  module Config
    # Default values for the supplejack configuration.
    #
    # These values can be overwritten in a rails initializer for example:
    #
    # /config/initializers/supplejack.rb
    #
    # Supplejack.configure do |config|
    #   config.api_key = "xxxx"
    #   config.api_url = "api.supplejack.org"
    #   etc....
    # end

    API_KEY                   = nil
    API_URL                   = 'http://api.digitalnz.org'
    URL_FORMAT                = :item_hash
    FACETS                    = [].freeze
    FACETS_PER_PAGE           = 10
    FACETS_SORT               = nil
    PER_PAGE                  = 20
    PAGINATION_LIMIT          = nil
    TIMEOUT                   = 30
    RECORD_KLASS              = 'Record'
    CURRENT_USER_METHOD       = :current_user
    SEARCH_KLASS              = nil
    FIELDS                    = [:default].freeze
    SUPPLEJACK_FIELDS         = [].freeze
    SPECIAL_FIELDS            = [].freeze
    ENABLE_DEBUGGING          = false
    ENABLE_CACHING            = false
    ATTRIBUTE_TAG             = :p
    LABEL_TAG                 = :strong
    LABEL_CLASS               = nil
    STICKY_FACETS             = false
    NON_TEXT_FIELDS           = [].freeze

    VALID_OPTIONS_KEYS = %i[
      api_key
      api_url
      facet_pivots
      facets
      facets_per_page
      facets_sort
      single_value_methods
      search_attributes
      url_format
      per_page
      pagination_limit
      timeout
      record_klass
      current_user_method
      search_klass
      fields
      supplejack_fields
      special_fields
      enable_debugging
      enable_caching
      attribute_tag
      label_tag
      label_class
      sticky_facets
      non_text_fields
    ].freeze

    SINGLE_VALUE_METHODS = [
      :description
    ].freeze

    SEARCH_ATTRIBUTES = [
      :location
    ].freeze

    attr_accessor *VALID_OPTIONS_KEYS

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    def configure
      yield self
    end

    def url_format_klass
      "Supplejack::UrlFormats::#{Supplejack.url_format.to_s.classify}".constantize
    end

    # Reset all configuration options to defaults
    def reset
      self.api_key                  = API_KEY
      self.api_url                  = API_URL
      self.facets                   = FACETS
      self.facets_per_page          = FACETS_PER_PAGE
      self.facets_sort              = FACETS_SORT
      self.sticky_facets            = STICKY_FACETS
      self.single_value_methods     = SINGLE_VALUE_METHODS
      self.search_attributes        = SEARCH_ATTRIBUTES
      self.url_format               = URL_FORMAT
      self.per_page                 = PER_PAGE
      self.pagination_limit         = PAGINATION_LIMIT
      self.timeout                  = TIMEOUT
      self.record_klass             = RECORD_KLASS
      self.current_user_method      = CURRENT_USER_METHOD
      self.search_klass             = SEARCH_KLASS
      self.fields                   = FIELDS
      self.supplejack_fields        = SUPPLEJACK_FIELDS
      self.special_fields           = SPECIAL_FIELDS
      self.enable_debugging         = ENABLE_DEBUGGING
      self.enable_caching           = ENABLE_CACHING
      self.attribute_tag            = ATTRIBUTE_TAG
      self.label_tag                = LABEL_TAG
      self.label_class              = LABEL_CLASS
      self.non_text_fields          = NON_TEXT_FIELDS
      self
    end
  end
end
