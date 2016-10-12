# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack
  class StoryItemRelation
    attr_reader :story

    def initialize(story)
      @story = story
      items_array = story.attributes.try(:fetch, :contents, nil) || []
      @items = items_array.map do |hash|
        Supplejack::StoryItem.new(hash.merge(story_id: story.id, api_key: story.api_key))
      end
    end

    def all
      @items
    end

    def build(attributes = {})
      story_item = Supplejack::StoryItem.new(attributes.merge(story_id: story.id, api_key: story.api_key))

      @items << story_item

      story_item
    end

    def create(attributes = {})
      story_item = build(attributes)
      story_item.save

      story_item
    end

    def find(id)
      @items.detect{|i| i.id.to_i == id.to_i}
    end

    # Any method missing on this class is delegated to the StoryItems objects array
    # so that the developer can easily execute any Array method on the StoryItemRelation
    #
    # @example
    #   story.each ....     => Iterate through the StoryItem objects array
    #   story.size          => Get the size of the StoryItem objects array
    #
    def method_missing(method, *args, &block)
      all.send(method, *args, &block)
    end
  end
end
