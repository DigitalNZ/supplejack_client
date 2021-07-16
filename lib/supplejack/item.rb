# frozen_string_literal: true

module Supplejack
  # The +Item+ class represents a SetItem on the Supplejack API
  #
  # An Item always belongs to a UserSet. In the API the SetItem class
  # only has a record_id and position, but it gets augmented with some
  # of the attributes of the Record that it represents.
  #
  # An Item object can have the following values:
  # - record_id
  # - position
  #
  # If more attributes of the Record are needed, they should be added to the SetItem::ATTRIBUTES
  # array in the API SetItem model.
  #
  class Item
    include Supplejack::Request

    ATTRIBUTES         = %i[record_id title description large_thumbnail_url thumbnail_url
                            contributing_partner display_content_partner display_collection
                            landing_url category date dnz_type dc_identifier creator].freeze
    SUPPORT_ATTRIBUTES = %i[attributes user_set_id].freeze
    ALL_ATTRIBUTES     = ATTRIBUTES + SUPPORT_ATTRIBUTES

    attr_reader *ALL_ATTRIBUTES
    attr_accessor :api_key, :errors, :position

    def initialize(attributes = {})
      @attributes = attributes.try(:symbolize_keys) || {}
      @user_set_id = @attributes[:user_set_id]
      @api_key = @attributes[:api_key]
      @position = @attributes[:position]

      ATTRIBUTES.each do |attribute|
        instance_variable_set("@#{attribute}", @attributes[attribute])
      end
    end

    def attributes
      Hash[ATTRIBUTES.map { |attr| [attr, send(attr)] }]
    end

    def id
      record_id
    end

    # Executes a POST request to the API to persist the current Item
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def save
      api_attributes = { record_id: record_id }
      api_attributes[:position] = position if position.present?
      post("/sets/#{user_set_id}/records", { api_key: api_key }, record: api_attributes)
      Rails.cache.delete("/users/#{api_key}/sets") if Supplejack.enable_caching
      true
    rescue StandardError => e
      self.errors = e.message
      false
    end

    # Executes a DELETE request to the API to remove the current Item
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      delete("/sets/#{user_set_id}/records/#{record_id}", api_key: api_key)
      Rails.cache.delete("/users/#{api_key}/sets") if Supplejack.enable_caching
      true
    rescue StandardError => e
      self.errors = e.message
      false
    end

    # Date getter to force the date attribute to be a Date object.
    #
    def date
      @date = @date.first if @date.is_a?(Array)

      return unless @date

      begin
        Time.parse(@date)
      rescue StandardError
        nil
      end
    end

    def method_missing(_symbol, *_args)
      nil
    end

    def respond_to_missing?(_symbol, *_args)
      true
    end
  end
end
