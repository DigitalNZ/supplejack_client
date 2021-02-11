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

    API_KEY                  = nil
    API_URL                  = 'http://api.digitalnz.org'
    ATTRIBUTE_TAG            = :p
    CURRENT_USER_METHOD      = :current_user
    ENABLE_DEBUGGING         = false
    ENABLE_CACHING           = false
    FACETS                   = [].freeze
    FACETS_PIVOTS            = [].freeze
    FACETS_PER_PAGE          = 10
    FACETS_SORT              = nil
    FIELDS                   = [:default].freeze
    LABEL_TAG                = :strong
    LABEL_CLASS              = nil
    NON_TEXT_FIELDS          = [].freeze
    PER_PAGE                 = 20
    PAGINATION_LIMIT         = nil
    RECORD_KLASS             = 'Record'
    SEARCH_KLASS             = nil
    SEARCH_ATTRIBUTES        = %i[location].freeze
    SINGLE_VALUE_METHODS     = %i[description].freeze
    STICKY_FACETS            = false
    SPECIAL_STORY_ATTRIBUTES = [].freeze
    SPECIAL_FIELDS           = [].freeze
    SUPPLEJACK_FIELDS        = [].freeze
    TIMEOUT                  = 30
    URL_FORMAT               = :item_hash

    VALID_OPTIONS_KEYS = %i[
      api_key
      api_url
      attribute_tag
      current_user_method
      enable_debugging
      enable_caching
      facet_pivots
      facets
      facets_per_page
      facets_sort
      fields
      label_tag
      label_class
      non_text_fields
      per_page
      pagination_limit
      record_klass
      search_attributes
      search_klass
      single_value_methods
      special_fields
      special_story_attributes
      sticky_facets
      supplejack_fields
      timeout
      url_format
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
      self.attribute_tag            = ATTRIBUTE_TAG
      self.current_user_method      = CURRENT_USER_METHOD
      self.enable_debugging         = ENABLE_DEBUGGING
      self.enable_caching           = ENABLE_CACHING
      self.facets                   = FACETS
      self.facet_pivots             = FACETS_PIVOTS
      self.facets_per_page          = FACETS_PER_PAGE
      self.facets_sort              = FACETS_SORT
      self.fields                   = FIELDS
      self.label_tag                = LABEL_TAG
      self.label_class              = LABEL_CLASS
      self.non_text_fields          = NON_TEXT_FIELDS
      self.per_page                 = PER_PAGE
      self.pagination_limit         = PAGINATION_LIMIT
      self.record_klass             = RECORD_KLASS
      self.sticky_facets            = STICKY_FACETS
      self.single_value_methods     = SINGLE_VALUE_METHODS
      self.search_attributes        = SEARCH_ATTRIBUTES
      self.search_klass             = SEARCH_KLASS
      self.supplejack_fields        = SUPPLEJACK_FIELDS
      self.special_fields           = SPECIAL_FIELDS
      self.special_story_attributes = SPECIAL_STORY_ATTRIBUTES
      self.timeout                  = TIMEOUT
      self.url_format               = URL_FORMAT

      self
    end
  end
end
