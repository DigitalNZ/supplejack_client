# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

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

    MODIFIABLE_ATTRIBUTES = [:position, :meta, :content, :type, :sub_type].freeze
    UNMODIFIABLE_ATTRIBUTES = [:id, :story_id].freeze
    ATTRIBUTES = (MODIFIABLE_ATTRIBUTES + UNMODIFIABLE_ATTRIBUTES).freeze

    attr_accessor *ATTRIBUTES
    attr_accessor :errors
    attr_reader :api_key

    def initialize(attributes={})
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
        self.send("#{attr}=", value) if ATTRIBUTES.include?(attr)
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
      begin
        if self.new_record?
          self.attributes = post(
            "/stories/#{story_id}/items",
            {api_key: api_key},
            {item: self.api_attributes}
          )
        else
          self.attributes = patch(
            "/stories/#{story_id}/items/#{id}",
            params: {api_key: api_key},
            payload: {item: self.api_attributes}
          )
        end

        Rails.cache.delete("/users/#{self.api_key}/stories") if Supplejack.enable_caching

        true
      rescue StandardError => e
        self.errors = e.message

        false
      end
    end

    # Executes a DELETE request to the API with the StoryItem ID and the stories api_key
    #
    # When the API returns an error response, the errors are available through the StoryItem#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      return false if self.new_record?

      begin
        delete("/stories/#{story_id}/items/#{id}", {api_key: api_key})

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
    def update_attributes(attributes={})
      self.attributes = attributes

      self.save
    end

    def to_json
      attributes.to_json
    end

    private

    def retrieve_attributes(attributes_list)
      attributes = {}

      attributes_list.each do |attribute|
        value = self.send(attribute)

        attributes[attribute] = value unless value.nil?
      end

      attributes
    end
  end
end
