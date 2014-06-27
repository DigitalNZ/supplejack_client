# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

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
    # CUSTOM_SEARCH             = nil
    FACETS                    = []
    FACETS_PER_PAGE           = 10
    FACETS_SORT               = nil
    # STICKY_FACETS             = false
    PER_PAGE                  = 20
    PAGINATION_LIMIT          = nil
    TIMEOUT                   = 30
    RECORD_KLASS              = 'Record'
    # CURRENT_USER_METHOD       = :current_user
    SEARCH_KLASS              = nil
    FIELDS                    = [:default]
    # DC_FIELDS                 = []
    SUPPLEJACK_FIELDS                = []
    ADMIN_FIELDS              = []
    # DCTERMS_FIELDS            = []
    # ATTRIBUTE_TAG             = :p
    # LABEL_TAG                 = :strong
    # LABEL_CLASS               = nil
    ENABLE_DEBUGGING          = false
    ENABLE_CACHING            = false

    VALID_OPTIONS_KEYS = [
      :api_key,
      :api_url,
    #   :custom_search,
      :facets,
      :facets_per_page,
      :facets_sort,
    #   :sticky_facets,
      :single_value_methods,
      :search_attributes,
      :url_format,
      :per_page,
      :pagination_limit,
      :timeout,
      :record_klass,
    #   :current_user_method,
      :search_klass,
      :fields,
    #   :dc_fields,
      :supplejack_fields,
      :admin_fields,
    #   :dcterms_fields,
    #   :attribute_tag,
    #   :label_tag,
    #   :label_class,
      :enable_debugging,
      :enable_caching
    ]

    SINGLE_VALUE_METHODS = [
      :description
      # :author,
      # :collection_name,
      # :content_partner,
      # :object_url,
      # :thumbnail_url
    ]

    SEARCH_ATTRIBUTES = [
      :location
      # :category,
      # :placename,
      # :content_partner,
      # :creator,
      # :rights,
      # :language,
      # :century,
      # :decade,
      # :year,
      # :collection,
      # :dc_type
    ]

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
      # self.custom_search            = CUSTOM_SEARCH
      self.facets                   = FACETS
      self.facets_per_page          = FACETS_PER_PAGE
      self.facets_sort              = FACETS_SORT
      # self.sticky_facets            = STICKY_FACETS
      self.single_value_methods     = SINGLE_VALUE_METHODS
      self.search_attributes        = SEARCH_ATTRIBUTES
      self.url_format               = URL_FORMAT
      self.per_page                 = PER_PAGE
      self.pagination_limit         = PAGINATION_LIMIT
      self.timeout                  = TIMEOUT
      self.record_klass             = RECORD_KLASS
      # self.current_user_method      = CURRENT_USER_METHOD
      self.search_klass             = SEARCH_KLASS
      self.fields                   = FIELDS
      # self.dc_fields                = DC_FIELDS
      self.supplejack_fields               = SUPPLEJACK_FIELDS
      self.admin_fields             = ADMIN_FIELDS
      # self.dcterms_fields           = DCTERMS_FIELDS
      # self.attribute_tag            = ATTRIBUTE_TAG
      # self.label_tag                = LABEL_TAG
      # self.label_class              = LABEL_CLASS
      self.enable_debugging         = ENABLE_DEBUGGING
      self.enable_caching           = ENABLE_CACHING
      
      self
    end
  end
end
