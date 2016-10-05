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
    UNMODIFIABLE_ATTRIBUTES = [:id, :created_at, :updated_at, :number_of_items].freeze
    ATTRIBUTES = (MODIFIABLE_ATTRIBUTES + UNMODIFIABLE_ATTRIBUTES).freeze

    attr_accessor *ATTRIBUTES
    attr_accessor :user, :errors

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
          response = self.class.post("/stories", {api_key: self.api_key}, {story: self.api_attributes})
          self.attributes = response["story"]
        else
          self.class.patch("/stories/#{self.id}", {api_key: self.api_key}, {story: self.api_attributes})
        end
        Rails.cache.delete("/users/#{self.api_key}/stories") if Supplejack.enable_caching
        return true
      rescue StandardError => e
        self.errors = e.inspect
        return false
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
    #
    # @return [String] User ApiKey
    def api_key
      @user.api_key
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