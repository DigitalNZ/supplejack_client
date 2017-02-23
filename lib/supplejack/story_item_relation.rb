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
    include Request

    attr_reader :story, :errors

    def initialize(story)
      @story = story
      items = story.attributes.try(:fetch, :contents, nil) || []
      build_items(items)
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
    end

    def move_item(item_id, position)
      begin
        response = post("/stories/#{story.id}/items/#{item_id}/moves", {api_key: story.api_key}, {item_id: item_id, position: position})

        build_items(response)

        true
      rescue StandardError => e
        @errors = e.inspect

        false
      end
    end

    def find(id)
      @items.detect{|i| i.id == id.to_i}
    end

    def to_json
      all.to_json
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

    private

    def build_items(items)
      @items = items.map do |hash|
        Supplejack::StoryItem.new(hash.merge(story_id: story.id, api_key: story.api_key))
      end.sort_by(&:position)
    end
  end
end
