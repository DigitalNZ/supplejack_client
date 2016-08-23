# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack

  # The +UserSetRelation+ class provides ActiveRecord like functionality to the
  # relationship between a User object and it's UserSet objects.
  # 
  # @exmaple 
  #   user = Supplejack::User.find(1)
  #
  #   user.sets.build({name: "Dogs and cats"})    => Returns a new UserSet object linked to the User
  #   user.sets.find(123)                         => Return a UserSet object which belongs to the User
  #   user.sets.order(:name)                      => Return a array of UserSet objects ordered by name
  #
  class UserSetRelation
    include Supplejack::Request

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Returns an array of UserSet objects and memoizes the array 
    #
    def sets
      @sets ||= self.fetch_sets
    end

    # Initialize an array of UserSet objects and orders them by priority.
    #
    # @return [ Array ] A Array of +Supplejack::UserSet+ objects
    #
    def fetch_sets
      response = sets_response
      sets_array = response["sets"] || []
      @sets = sets_array.map {|attributes| Supplejack::UserSet.new(attributes) }.sort_by { |set| set.priority }
    end

    # Execute a GET request to the API to retrieve the user_sets from a User.
    # It caches the response from the API for a day. The cache is invalidated
    # every time any set for the user changes.
    #
    # @return [ Hash ] A hash parsed from a JSON string. See the API Documentation for more details.
    #
    def sets_response
      params = {}

      if user.use_own_api_key?
        path = "/sets"
        params[:api_key] = user.api_key
      else
        path = "/users/#{user.api_key}/sets"
      end

      if Supplejack.enable_caching
        Rails.cache.fetch(path, expires_in: 1.day) do
          get(path, params)
        end
      else
        get(path, params)
      end
    end

    # Finds a UserSet object with the provided ID that belongs to the current
    # User
    #
    # @param [ String ] A 24 character string representing the UserSet ID
    #
    # @return [ Supplejack::UserSet ] A UserSet object
    #
    def find(user_set_id)
      Supplejack::UserSet.find(user_set_id, self.user.api_key)
    end

    # Initializes a new UserSet object and links it to the current User
    #
    # @param [ Hash ] A hash with the UserSet field names and values
    #
    # @return [ Supplejack::UserSet] A new UserSet object 
    #
    def build(attributes={})
      user_set = Supplejack::UserSet.new(attributes)
      user_set.api_key = user.api_key
      user_set
    end

    # Build and persist a UserSet object with the provided attributes
    #
    # @param [ Hash ] A hash with the UserSet field names and values
    #
    # @return [ Supplejack::UserSet ] A persisted UserSet object
    #
    def create(attributes={})
      user_set = self.build(attributes)
      user_set.save
      user_set
    end

    # Return a array of UserSet objects ordered by the priority first and then
    # in ascending order by the specified attribute.
    # 
    # The only exception is for the "updated_at" attribute, for which ignores
    # the priority and orders on descending order.
    #
    # @param [ Symbol ] A symbol with the attribute to order the UserSet objects on.
    #
    # @return [ Array ] A array of Supplejack::UserSet objects.
    # 
    def order(attribute)
      @sets = sets.sort_by do |set|
        value = set.send(attribute)
        value = value.downcase if value.is_a?(String)
        attribute == :updated_at ? value : [set.priority, value]
      end
      @sets = @sets.reverse if attribute == :updated_at
      @sets
    end

    # Returns an array of all UserSet objects for the current User
    # 
    def all
      self.sets
    end

    # Any method missing on this class is delegated to the UserSet objects array
    # so that the developer can easily execute any Array method on the UserSetRelation
    #
    # @example
    #   user.sets.each ....     => Iterate through the UserSet objects array
    #   user.sets.size          => Get the size of the UserSet objects array
    # 
    def method_missing(method, *args, &block)
      sets.send(method, *args, &block)
    end

  end
end
