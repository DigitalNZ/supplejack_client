# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack

  class Story
    extend Supplejack::Request
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    MODIFIABLE_ATTRIBUTES = [:name, :description, :privacy, :featured, :approved, :tags].freeze
    UNMODIFIABLE_ATTRIBUTES = [:id, :created_at, :updated_at, :number_of_items, :contents].freeze
    ATTRIBUTES = (MODIFIABLE_ATTRIBUTES + UNMODIFIABLE_ATTRIBUTES).freeze

    attr_accessor *ATTRIBUTES
    attr_accessor :user, :errors, :api_key

    # Define setter methods for both created_at and updated_at so that
    # they always return a Time object.
    #
    [:created_at, :updated_at].each do |attribute|
      define_method("#{attribute}=") do |time|
        self.instance_variable_set("@#{attribute}", Util.time(time))
      end
    end

    def initialize(attributes={})
      @attributes = attributes.try(:symbolize_keys) || {}
      @user = Supplejack::User.new(@attributes[:user])
      self.attributes = @attributes
    end

    def items
      @items ||= StoryItemRelation.new(self)
    end

    # Returns if the Story is persisted to the API or not.
    #
    # @return [ true, false ] True if the UserSet is persisted to the API, false if not.
    #
    def new_record?
      self.id.blank?
    end

    def attributes
      retrieve_attributes(ATTRIBUTES)
    end

    def api_attributes
      retrieve_attributes(MODIFIABLE_ATTRIBUTES)
    end

    # Executes a POST request when the Story hasn't been persisted to the API, otherwise it executes
    # a PATCH request.
    #
    # When the API returns a error response, the errors are available through the Story#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def save
      begin
        if self.new_record?
          self.attributes = self.class.post("/stories", {api_key: self.api_key}, {story: self.api_attributes})
        else
          self.attributes = self.class.patch("/stories/#{self.id}", payload: {story: self.api_attributes})
        end

        Rails.cache.delete("/users/#{self.api_key}/stories") if Supplejack.enable_caching

        true
      rescue StandardError => e
        self.errors = e.inspect

        false
      end
    end

    # Executes a DELETE request to the API with the Story ID and the user's api_key
    #
    # When the API returns a error response, the errors are available through the Story#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      return false if self.new_record?

      begin
        self.class.delete("/stories/#{self.id}")

        Rails.cache.delete("/users/#{self.api_key}/stories") if Supplejack.enable_caching

        true
      rescue StandardError => e
        self.errors = e.inspect

        false
      end
    end

    # Fetches the Story information from the API again, in case it had changed.
    #
    # This can be useful if they items for a Story changed and you want the relation
    # to have the most up to date items.
    #
    def reload
      begin
        self.attributes = self.class.get("/stories/#{self.id}")
        @items = nil
      rescue RestClient::ResourceNotFound
        raise Supplejack::StoryNotFound, "Story with ID #{id} was not found"
      end
    end

    # Executes a GET request with the provided Story ID and initializes
    # a Story object with the response from the API.
    #
    # @return [ Story ] A Story object
    #
    def self.find(id, api_key: nil, params: {})
      begin
        response = get("/stories/#{id}", params)
        attributes = response || {}

        story = new(attributes)
        story.api_key = api_key if api_key.present?

        story
      rescue RestClient::ResourceNotFound
        raise Supplejack::StoryNotFound, "Story with ID #{id} was not found"
      end
    end

    # Assigns the provided attributes to the Story object
    #
    def attributes=(attributes)
      attributes = attributes.try(:symbolize_keys) || {}
      attributes.each do |attr, value|
        self.send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
    end

    # Updates the Story attributes and persists it to the API
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def update_attributes(attributes={})
      self.attributes = attributes

      self.save
    end

    # Returns the ApiKey of the User this Story belongs to
    # If the api_key is set on the Story directly it uses that one instead
    #
    # @return [String] User ApiKey
    def api_key
      @api_key || @user.api_key
    end

    # Returns a comma separated list of tags for this Story
    #
    def tag_list
      self.tags.join(', ') if self.tags
    end

    def private?
      self.privacy == "private"
    end

    def public?
      self.privacy == "public"
    end

    def hidden?
      self.privacy == "hidden"
    end

    # A Story is viewable by anyone if it's public or hidden
    # When the Story is private it's only viewable by the owner.
    #
    # @param [ Supplejack::User ] User to check if they can see it
    #
    # @return [ true, false ] True if the user can view the current Story, false if not.
    #
    def viewable_by?(user)
      return true if self.public? || self.hidden?

      self.owned_by?(user)
    end

    # Compares the api_key of the user and the api_key assigned to the Story
    # to find out if the user passed is the owner of the story.
    #
    # @param [ Supplejack::User ] User to check if they own it
    #
    # @return [ true, false ] True if the user owns the current Story, false if not.
    #
    def owned_by?(user)
      return false if user.try(:api_key).blank? || self.api_key.blank?

      user.try(:api_key) == self.api_key
    end

    def to_json
      attributes.to_json
    end

    private

    def retrieve_attributes(attributes_list)
      attributes = {}
      attributes_list.each do |attribute|
        value = self.send(attribute)
        attributes[attribute] = value if value.present?
      end
      attributes
    end

  end
end
