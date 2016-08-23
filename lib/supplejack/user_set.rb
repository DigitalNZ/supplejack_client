# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack

  # The +UserSet+ class represents a UserSet on the Supplejack API
  #
  # A UserSet instance can have many Item objects, the relationship
  # with the Item objects is managed through the ItemRelation class which adds
  # ActiveRecord like behaviour to the relationship.
  #
  # A Item object can have the following values:
  # - id
  # - name
  # - description
  # - privacy
  # - priority
  # - count
  # - tags
  # 
  class UserSet
    extend Supplejack::Request
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    ATTRIBUTES = [:id, :name, :description, :privacy, :url, :priority, :count, :tags, :tag_list, 
                  :featured, :records, :created_at, :updated_at, :approved, :record]
    attr_accessor *ATTRIBUTES
    attr_accessor :api_key, :errors, :user

    PRIVACY_STATES = ['public', 'hidden', 'private']
    
    def initialize(attributes={})
      @attributes = attributes.try(:symbolize_keys) || {}
      @user = Supplejack::User.new(@attributes[:user])
      self.attributes = @attributes
    end

    def attributes
      attributes = {}
      ATTRIBUTES.each do |attribute|
        value = self.send(attribute)
        attributes[attribute] = value if value.present?
      end
      attributes
    end

    # Return a Hash of attributes which is used to extract the relevant
    # UserSet attributes when creating or updating a UserSet
    #
    # @return [ Hash ] A hash with field names and their values
    #
    def api_attributes
      api_attributes = {}
      [:name, :description, :privacy, :priority, :tag_list, :featured, :approved].each do |attr|
        api_attributes[attr] = self.send(attr)
      end
      api_attributes[:records] = self.api_records
      api_attributes
    end

    # Return a array of hashes with the format: {record_id: 123, position: 1}
    # Each hash represents a Supplejack::Item within the UserSet
    #
    # This array is used to send the UserSet items information to the API.
    #
    # @return [ Array ] An array of Hashes.
    #
    def api_records
      records = self.records.is_a?(Array) ? self.records : []
      records.map do |record_hash| 
        record_hash = record_hash.try(:symbolize_keys) || {}
        if record_hash[:record_id]
          {record_id: record_hash[:record_id], position: record_hash[:position] }
        else
          nil
        end
      end.compact
    end

    # Initializes a ItemRelation class which adds behaviour to build, create and
    # find items related to this particular UserSet instance
    #
    # @return [ ItemRelation ] A ItemRelation object
    #
    def items
      @items ||= ItemRelation.new(self)
    end

    # Returns the UserSet priority which defaults to 1
    #
    def priority
      @priority || 1
    end

    # Returns the api_key from the UserSet or from the User which this set belongs to.
    # 
    def api_key
      @api_key || @user.try(:api_key)
    end

    # Returns a comma separated list of tags for this UserSet
    #
    def tag_list
      return @tag_list if @tag_list
      self.tags.join(', ') if self.tags
    end

    def favourite?
      self.name == "Favourites"
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

    # Convinience method to find out if a particular record_id is part of the UserSet
    #
    # @param [ Integer ] A record_id
    #
    # @return [ true, false ] True if the provided record_id is part of the UserSet, false otherwise.
    #
    def has_record?(record_id)
      !!self.items.detect {|i| i.record_id == record_id.to_i }
    end

    # Returns the record id of the associated record in a safe manner
    #
    # @return [Intger, nil ] the record id if it exists, false otherwise
    def set_record_id
      self.record['record_id'] if self.record
    end

    # Executes a POST request when the UserSet hasn't been persisted to the API, otherwise it executes
    # a PUT request.
    #
    # When the API returns a error response, the errors are available through the UserSet#errors 
    # virtual attribute.
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    # 
    def save
      begin
        if self.new_record?
          response = self.class.post("/sets", {api_key: self.api_key}, {set: self.api_attributes})
          self.id = response["set"]["id"]
        else
          self.class.put("/sets/#{self.id}", {api_key: self.api_key}, {set: self.api_attributes})
        end
        Rails.cache.delete("/users/#{self.api_key}/sets") if Supplejack.enable_caching
        return true
      rescue StandardError => e
        self.errors = e.inspect
        return false
      end
    end

    # Updates the UserSet attributes and persists it to the API
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def update_attributes(attributes={})
      self.attributes = attributes
      self.save
    end

    # Assigns the provided attributes to the UserSet object
    # 
    def attributes=(attributes)
      attributes = attributes.try(:symbolize_keys) || {}
      attributes.each do |attr, value|
        self.send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
      self.records = ordered_records_from_array(attributes[:ordered_records]) if attributes[:ordered_records]
    end

    # Define setter methods for both created_at and updated_at so that
    # they always return a Time object.
    # 
    [:created_at, :updated_at].each do |attribute|
      define_method("#{attribute}=") do |time|
        self.instance_variable_set("@#{attribute}", Util.time(time))
      end
    end

    # Takes an ordered Array of record_ids and converts it into a Array
    # of Hashes which the API expects, inferring the position value from
    # the position of the record_id in the Array.
    #
    # @param [ Array ] A array of record_ids
    #
    # @return [ Array ] A array of hashes in the format {record_id: 1, position: 1}
    #
    # @example
    #   user_set.ordered_records_from_array([89,66]) => [{record_id: 89, position: 1}, {record_id: 66, position: 2}]
    #
    def ordered_records_from_array(record_ids)
      records = []
      record_ids.each_with_index do |id, index|
        records << {record_id: id, position: index+1}
      end
      records
    end

    # Returns if the UserSet is persisted to the API or not.
    #
    # @return [ true, false ] True if the UserSet is persisted to the API, false if not.
    #
    def new_record?
      self.id.blank?
    end

    # Executes a DELETE request to the API with the UserSet ID and the user's api_key
    # 
    # @return [ true, false ] True if the API response was successful, false if not.
    # 
    def destroy
      if self.new_record?
        return false
      else
        begin
          self.class.delete("/sets/#{self.id}", {api_key: self.api_key})
          Rails.cache.delete("/users/#{self.api_key}/sets") if Supplejack.enable_caching
          return true
        rescue StandardError => e
          self.errors = e.inspect
          return false
        end
      end
    end

    def persisted?
      !new_record?
    end

    # Fetches the UserSet information from the API again, in case it had changed.
    # This can be useful if they items for a UserSet changed and you want the relation
    # to have the most up to date items.
    # 
    def reload
      begin
        self.instance_variable_set("@items", nil)
        self.attributes = self.class.get("/sets/#{self.id}")["set"]
      rescue RestClient::ResourceNotFound => e
        raise Supplejack::SetNotFound, "UserSet with ID #{id} was not found"
      end
    end

    # A UserSet is viewable by anyone if it's public or hidden
    # When the UserSet is private it's only viewable by the owner.
    #
    # @param [ Supplejack::User ] A Supplejack::User object
    #
    # @return [ true, false ] True if the user can view the current UserSet, false if not.
    # 
    def viewable_by?(user)
      return true if self.public? || self.hidden?
      self.owned_by?(user)
    end

    # Compares the api_key of the user and the api_key assigned to the UserSet
    # to find out if the user passed is the owner of the set.
    #
    # @param [ Supplejack::User ] A Supplejack::User object
    #
    # @return [ true, false ] True if the user owns the current UserSet, false if not.
    #
    def owned_by?(user)
      return false if user.try(:api_key).blank? || self.api_key.blank?
      user.try(:api_key) == self.api_key
    end

    # Executes a GET request with the provided UserSet ID and initializes
    # a UserSet object with the response from the API.
    #
    # @return [ UserSet ] A UserSet object
    # 
    def self.find(id, api_key=nil)
      begin
        response = get("/sets/#{id}")
        attributes = response["set"] || {}
        user_set = new(attributes)
        user_set.api_key = api_key if api_key.present?
        user_set
      rescue RestClient::ResourceNotFound => e
        raise Supplejack::SetNotFound, "UserSet with ID #{id} was not found"
      end
    end

    # Executes a GET request to the API /sets/public endpoint to retrieve
    # all public UserSet objects.
    #
    # @param [ Hash ] options Supported options: :page, :per_page
    #
    # @option options [ Integer ] :page The page number used to paginate through the UserSet objects
    # @option options [ Integer ] :per_page The per_page number to select the number of UserSet objects per page.
    #
    # @return [ Array ] A array of Supplejack::UserSet objects
    # 
    def self.public_sets(options={})
      options.reverse_merge!(page: 1, per_page: 100)
      response = get("/sets/public", options)
      sets_array = response["sets"] || []
      user_sets = sets_array.map {|attrs| new(attrs) }
      Supplejack::PaginatedCollection.new(user_sets, 
                                          options[:page].to_i, 
                                          options[:per_page].to_i, 
                                          response["total"].to_i)
    end

    # Execute a GET request to the API /sets/featured endpoint to retrieve
    # all UserSet objects which have the :featured flag set to true
    #
    # @return [ Array ] A array of Supplejack::UserSet objects
    #
    def self.featured_sets
      path = "/sets/featured"
      if Supplejack.enable_caching
        response = Rails.cache.fetch(path, expires_in: 1.day) do
          get(path)
        end
      else
        response = get(path)
      end
      sets_array = response["sets"] || []
      user_sets = sets_array.map {|attrs| new(attrs) }
    end

    # This method is normally provided by ActiveModel::Naming module, but here we have to override it
    # so that in the Supplejack Website application it behaves as if the Supplejack::UserSet class was not under the
    # Supplejack namespace.
    #
    # This is useful when using a Supplejack::UserSet object in the Rails provided routes helpers. Example:
    #
    #   user_set_path(@user_set)
    # 
    def self.model_name
      ActiveModel::Name.new(self, nil, "UserSet")
    end
  end
end
