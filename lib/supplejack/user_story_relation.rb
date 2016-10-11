# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack
  class UserStoryRelation
    include Supplejack::Request

    attr_reader :user

    def initialize(user)
      @user = user
      @stories = []
      @initial_fetch = false
    end

    # Returns an array of Story objects and memoizes the array
    #
    def fetch(force: false)
      fetch_stories = -> { fetch_api_stories.map{|s| Supplejack::Story.new(s.merge(user: user))} }

      @stories = if force
                   fetch_stories.call
                  elsif !@initial_fetch
                    @initial_fetch = true
                    fetch_stories.call
                  else
                    @stories
                  end

      @stories
    end
    alias_method :all, :fetch

    # Finds a Story object with the provided ID that belongs to the current
    # User
    #
    # @param [ String ] A 24 character string representing the Story ID
    #
    # @return [ Supplejack::Story ] A Story object
    #
    def find(story_id)
      story = Supplejack::Story.find(story_id)
      story.api_key = user.api_key

      story
    end

    # Initializes a new Story object and links it to the current User
    #
    # @param [ Hash ] A hash with the Story field names and values
    #
    # @return [ Supplejack::Story] A new Story object
    #
    def build(attributes={})
      story = Supplejack::Story.new(attributes)
      story.api_key = user.api_key

      # Possible at some point in the future we'll want
      # to change this to something more robust.
      #
      # Just not sure if unsaved Stories being in this
      # will ever be a problem or not
      @stories << story

      story
    end

    # Build and persist a Story object with the provided attributes
    #
    # @param [ Hash ] A hash with the Story field names and values
    #
    # @return [ Supplejack::Story ] A persisted Story object
    #
    def create(attributes={})
      story = build(attributes)
      story.save

      story
    end

    # Return an array of Story objects ordered in ascending order
    # by the specified attribute.
    #
    # @param [ Symbol ] A symbol with the attribute to order the Story objects on
    #
    # @return [ Array ] A array of Supplejack::Story objects.
    #
    def order(attribute)
      @stories = all.sort_by do |story|
        value = story.send(attribute)
        value = value.downcase if value.is_a?(String)

        value
      end
    end

    # Any method missing on this class is delegated to the Stories objects array
    # so that the developer can easily execute any Array method on the UserSttoryRelation
    #
    # @example
    #   user.stories.each ....     => Iterate through the Story objects array
    #   user.stories.size          => Get the size of the Story objects array
    #
    def method_missing(method, *args, &block)
      all.send(method, *args, &block)
    end

    private

    def fetch_api_stories
      params = {}

      if user.use_own_api_key?
        path = "/stories"
        params[:api_key] = user.api_key
      else
        path = "/users/#{user.api_key}/stories"
      end

      if Supplejack.enable_caching
        Rails.cache.fetch(path, expires_in: 1.day) do
          get(path, params)
        end
      else
        get(path, params)
      end
    end
  end
end
