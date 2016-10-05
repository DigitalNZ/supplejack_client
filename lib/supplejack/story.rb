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
    attr_accessor :user

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

    def attributes
      retrieve_attributes(ATTRIBUTES)
    end

    def api_attributes
      retrieve_attributes(MODIFIABLE_ATTRIBUTES)
    end

    # Assigns the provided attributes to the Story object
    #
    def attributes=(attributes)
      attributes = attributes.try(:symbolize_keys) || {}
      attributes.each do |attr, value|
        self.send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
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
