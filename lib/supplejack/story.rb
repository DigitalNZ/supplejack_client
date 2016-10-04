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

    ATTRIBUTES = [:id, :name, :created_at, :updated_at, :privacy, :featured, :approved, :description,
                  :tags, :number_of_items, :contents].freeze
    attr_accessor *ATTRIBUTES

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

    # Assigns the provided attributes to the Story object
    #
    def attributes=(attributes)
      attributes = attributes.try(:symbolize_keys) || {}
      attributes.each do |attr, value|
        self.send("#{attr}=", value) if ATTRIBUTES.include?(attr)
      end
    end

  end
end
