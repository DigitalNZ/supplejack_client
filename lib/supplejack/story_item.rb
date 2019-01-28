# frozen_string_literal: true

module Supplejack
  # The +StoryItem+ class represents a StoryItem on the Supplejack API
  #
  # A StoryItem always belongs to a Story. represents.
  #
  # A StoryItem object has the following values:
  # - id
  # - type
  # - sub_type
  # - position
  # - meta [Hash]
  # - content [Hash]
  class StoryItem
    include Supplejack::Request

    MODIFIABLE_ATTRIBUTES = %i[position meta content type sub_type record_id].freeze
    UNMODIFIABLE_ATTRIBUTES = %i[id story_id].freeze
    ATTRIBUTES = (MODIFIABLE_ATTRIBUTES + UNMODIFIABLE_ATTRIBUTES).freeze

    attr_accessor *ATTRIBUTES
    attr_accessor :errors
    attr_reader :api_key

    def initialize(attributes = {})
      @attributes = attributes.try(:deep_symbolize_keys) || {}
      @api_key = @attributes[:api_key]

      self.meta ||= {}
      self.attributes = @attributes
    end

    # Assigns the provided attributes to the StoryItem object
    #
    def attributes=(attributes)
      attributes = attributes.try(:deep_symbolize_keys) || {}

      attributes.each do |attr, value|
        send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
    end

    def attributes
      retrieve_attributes(ATTRIBUTES)
    end

    def api_attributes
      retrieve_attributes(MODIFIABLE_ATTRIBUTES)
    end

    def new_record?
      id.nil?
    end

    # Executes a POST request when the StoryItem hasn't been persisted to
    # the API, otherwise it execute a PATCH request.
    #
    # When the API returns a error response, the errors are available through the Story#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def save
      self.attributes = if new_record?
                          post(
                            "/stories/#{story_id}/items",
                            { user_key: api_key },
                            item: api_attributes
                          )
                        else
                          patch(
                            "/stories/#{story_id}/items/#{id}",
                            { user_key: api_key },
                            item: api_attributes
                          )
                        end

      Rails.cache.delete("/users/#{api_key}/stories") if Supplejack.enable_caching

      true
    rescue StandardError => e
      self.errors = e.message

      false
    end

    # Executes a DELETE request to the API with the StoryItem ID and the stories api_key
    #
    # When the API returns an error response, the errors are available through the StoryItem#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      return false if new_record?

      begin
        delete("/stories/#{story_id}/items/#{id}", user_key: api_key)

        Rails.cache.delete("/users/#{api_key}/stories") if Supplejack.enable_caching

        true
      rescue StandardError => e
        self.errors = e.message

        false
      end
    end

    # Updates the StoryItems attributes and persists it to the API
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def update_attributes(attributes = {})
      self.attributes = attributes

      save
    end

    delegate :to_json, to: :attributes

    private

    def retrieve_attributes(attributes_list)
      attributes = {}

      attributes_list.each do |attribute|
        value = send(attribute)

        attributes[attribute] = value unless value.nil?
      end

      attributes
    end
  end
end
