# frozen_string_literal: true

module Supplejack
  # The +ItemRelation+ class provides ActiveRecord like functionality to the
  # relationship between a UserSet object and it's Item objects.
  #
  # @exmaple
  #   user_set = user.sets.first
  #
  #   user_set.items.build({record_id: 1})              => Returns a new Item object linked to the UserSet
  #   user_set.items.find(1)                            => Return a Item object which belongs to the UserSet
  #
  class ItemRelation
    include Supplejack::Request

    attr_reader :user_set, :items

    def initialize(user_set)
      @user_set = user_set
      items_array = user_set.attributes[:records] || []
      @items = items_array.map do |hash|
        Supplejack::Item.new(hash.merge(user_set_id: user_set.id, api_key: user_set.api_key))
      end
    end

    # Returns an Array with all items for the current UserSet
    #
    def all
      @items
    end

    # Finds the item based on the record_id and returns it.
    #
    def find(record_id)
      @items.detect { |i| i.record_id == record_id.to_i }
    end

    # Initializes a new Item with the provided attributes
    #
    # @return [ Supplejack::Item ] A new Supplejack::Item object
    #
    def build(attributes = {})
      attributes ||= {}
      attributes[:user_set_id] = user_set.id
      attributes[:api_key] = user_set.api_key
      Supplejack::Item.new(attributes)
    end

    # Initializes and persists the Item to the API
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def create(attributes = {})
      item = build(attributes)

      item.save
    end

    # Any method missing on this class is delegated to the Item objects array
    # so that the developer can easily execute any Array method on the ItemRelation
    #
    # @example
    #   user_set.items.each ....     => Iterate through the Item objects array
    #   user_set.items.size          => Get the size of the Item objects array
    #
    def method_missing(method, *args, &block)
      @items.send(method, *args, &block)
    end
  end
end
