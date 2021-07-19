# frozen_string_literal: true

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

    def find(id)
      @items.detect { |i| i.id.to_s == id.to_s }
    end

    delegate :to_json, to: :all

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

    def respond_to_missing?(_method, *_args, &_blocks)
      true
    end

    private

    def build_items(items)
      @items = items.map do |hash|
        Supplejack::StoryItem.new(hash.merge(story_id: story.id, api_key: story.api_key))
      end.sort_by(&:position)
    end
  end
end
