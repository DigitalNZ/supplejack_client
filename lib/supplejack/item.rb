# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

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
    
    ATTRIBUTES = [:record_id, :title, :description, :large_thumbnail_url, :thumbnail_url, 
                  :contributing_partner, :display_content_partner, :display_collection, :landing_url, :category, :date, 
                  :dnz_type, :dc_identifier, :creator]

    attr_reader *ATTRIBUTES
    attr_reader :attributes, :user_set_id
    attr_accessor :api_key, :errors, :position

    def initialize(attributes={})
      @attributes = attributes.try(:symbolize_keys) || {}
      @user_set_id = @attributes[:user_set_id]
      @api_key = @attributes[:api_key]
      @position = @attributes[:position]

      ATTRIBUTES.each do |attribute|
        self.instance_variable_set("@#{attribute}", @attributes[attribute])
      end
    end

    def attributes
      Hash[ATTRIBUTES.map {|attr| [attr, self.send(attr)]}]
    end

    def id
      self.record_id
    end

    # Executes a POST request to the API to persist the current Item
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def save
      begin
        api_attributes = {record_id: self.record_id}
        api_attributes[:position] = self.position if self.position.present?
        post("/sets/#{self.user_set_id}/records", {api_key: self.api_key}, {record: api_attributes})
        Rails.cache.delete("/users/#{self.api_key}/sets") if Supplejack.enable_caching
        return true
      rescue StandardError => e
        self.errors = e.message
        return false
      end
    end

    # Executes a DELETE request to the API to remove the current Item
    #
    # @return [ true, false ] True if the API response was successful, false if not.
    #
    def destroy
      begin
        delete("/sets/#{self.user_set_id}/records/#{self.record_id}", {api_key: self.api_key})
        Rails.cache.delete("/users/#{self.api_key}/sets") if Supplejack.enable_caching
        return true
      rescue StandardError => e
        self.errors = e.message
        return false
      end
    end

    # Date getter to force the date attribute to be a Date object.
    #
    def date
      @date = @date.first if @date.is_a?(Array)
      Time.parse(@date) rescue nil if @date
    end

    def method_missing(symbol, *args, &block)
      return nil
    end
  end
end
