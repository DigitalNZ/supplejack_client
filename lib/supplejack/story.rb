# frozen_string_literal: true

module Supplejack
  class Story
    extend Supplejack::Request
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    MODIFIABLE_ATTRIBUTES = %i[name description privacy copyright featured approved tags subjects record_ids count featured_at category].freeze
    UNMODIFIABLE_ATTRIBUTES = %i[id created_at updated_at number_of_items contents cover_thumbnail creator user_id username].freeze
    ATTRIBUTES = (MODIFIABLE_ATTRIBUTES + UNMODIFIABLE_ATTRIBUTES).freeze

    attr_accessor *ATTRIBUTES
    attr_accessor :user, :errors, :api_key

    # Define setter methods for both created_at and updated_at so that
    # they always return a Time object.
    #
    %i[created_at updated_at].each do |attribute|
      define_method("#{attribute}=") do |time|
        instance_variable_set("@#{attribute}", Util.time(time))
      end
    end

    def initialize(attributes = {})
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
      id.blank?
    end

    def attributes
      retrieve_attributes(ATTRIBUTES + Supplejack.special_story_attributes)
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
      # rubocop:disable Style/ConditionalAssignment
      if new_record?
        self.attributes = self.class.post('/stories', { user_key: api_key }, story: api_attributes)
      else
        self.attributes = self.class.patch("/stories/#{id}", { user_key: api_key }, story: api_attributes)
      end
      # rubocop:enable Style/ConditionalAssignment

      Rails.cache.delete("/users/#{api_key}/stories") if Supplejack.enable_caching

      true
    rescue StandardError => e
      self.errors = e.message

      false
    end

    # Executes a DELETE request to the API with the Story ID and the user's api_key
    #
    # When the API returns a error response, the errors are available through the Story#errors
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      return false if new_record?

      begin
        self.class.delete("/stories/#{id}", user_key: api_key)

        Rails.cache.delete("/users/#{api_key}/stories") if Supplejack.enable_caching

        true
      rescue StandardError => e
        self.errors = e.message

        false
      end
    end

    # Executes a POST request to the API with the Story ID, the user's api_key &
    # an Array of Hashes for item positions ex: [{ id: 'storyitemid', position: 100 }]
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def reposition_items(positions)
      self.class.post("/stories/#{id}/reposition_items", { user_key: api_key }, items: positions)

      Rails.cache.delete("/users/#{api_key}/stories") if Supplejack.enable_caching

      true
    rescue StandardError => e
      self.errors = e.message

      false
    end

    # Fetches the Story information from the API again, in case it had changed.
    #
    # This can be useful if they items for a Story changed and you want the relation
    # to have the most up to date items.
    #
    def reload
      self.attributes = self.class.get("/stories/#{id}")
      @items = nil
    rescue RestClient::ResourceNotFound
      raise Supplejack::StoryNotFound, "Story with ID #{id} was not found"
    end

    # Executes a GET request with the provided Story ID and initializes
    # a Story object with the response from the API.
    # If api_key provided, it will be used as the api_key in the request.
    #
    # @return [ Story ] A Story object
    #
    def self.find(id, user_key: nil, params: {})
      params[:user_key] = user_key if user_key
      begin
        response = get("/stories/#{id}", params)
        attributes = response || {}

        story = new(attributes)
        story.api_key = user_key if user_key.present?

        story
      rescue RestClient::ResourceNotFound
        raise Supplejack::StoryNotFound, "Story with ID #{id} was not found"
      rescue RestClient::Unauthorized
        raise Supplejack::StoryUnauthorised, "Story with ID #{id} is private and requires creators api_key"
      end
    end

    # Fetches featured stories
    #
    def self.featured
      get('/stories/featured')
    rescue RestClient::ServiceUnavailable
      raise Supplejack::ApiNotAvailable, 'API is not responding'
    end

    # Assigns the provided attributes to the Story object
    #
    def attributes=(attributes)
      attributes = attributes.try(:symbolize_keys) || {}
      attributes.each do |attr, value|
        send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
    end

    # Updates the Story attributes and persists it to the API
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def update_attributes(attributes = {})
      self.attributes = attributes

      save
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
      tags.join(', ') if tags
    end

    def private?
      privacy == 'private'
    end

    def public?
      privacy == 'public'
    end

    def hidden?
      privacy == 'hidden'
    end

    # A Story is viewable by anyone if it's public or hidden
    # When the Story is private it's only viewable by the owner.
    #
    # @param [ Supplejack::User ] User to check if they can see it
    #
    # @return [ true, false ] True if the user can view the current Story, false if not.
    #
    def viewable_by?(user)
      return true if public? || hidden?

      owned_by?(user)
    end

    # Executes a GET request to the API /stories/moderations endpoint to retrieve
    # all public UserSet objects.
    #
    # @return [ Array ] A array of Supplejack::UserSet objects

    def self.all_public_stories(options = {})
      response = get('/stories/moderations', options)
      response['sets'].map! { |attrs| new(attrs) } || []
      options[:meta_included] ? response : response['sets']
    end

    # Compares the api_key of the user and the api_key assigned to the Story
    # to find out if the user passed is the owner of the story.
    #
    # @param [ Supplejack::User ] User to check if they own it
    #
    # @return [ true, false ] True if the user owns the current Story, false if not.
    #
    def owned_by?(user)
      return false if user.try(:api_key).blank? || api_key.blank?

      user.try(:api_key) == api_key
    end

    def as_json(include_contents: true)
      include_contents ? attributes : attributes.except(:contents)
    end

    def to_json(include_contents: true)
      as_json(include_contents: include_contents).to_json
    end

    private

    def retrieve_attributes(attributes_list)
      {}.tap do |attributes|
        attributes_list.each do |attribute|
          value = ATTRIBUTES.include?(attribute) ? send(attribute) : @attributes[attribute]
          attributes[attribute] = value
        end
      end
    end
  end
end
