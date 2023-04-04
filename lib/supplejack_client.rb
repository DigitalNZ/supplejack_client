# frozen_string_literal: true

begin
  require 'pry'
rescue LoadError
  nil
end

require 'supplejack/config'
require 'supplejack/version'

module Supplejack
  extend Config

  require 'supplejack/engine'

  # alphabetically ordered
  require 'supplejack/concept'
  require 'supplejack/controllers/helpers'
  require 'supplejack/exceptions'
  require 'supplejack/facet'
  require 'supplejack/item'
  require 'supplejack/item_relation'
  require 'supplejack/log_subscriber'
  require 'supplejack/moderation_record'
  require 'supplejack/more_like_this_record'
  require 'supplejack/paginated_collection'
  require 'supplejack/record'
  require 'supplejack/request'
  require 'supplejack/story'
  require 'supplejack/story_item'
  require 'supplejack/story_item_relation'
  require 'supplejack/url_formats/item_hash'
  require 'supplejack/user'
  require 'supplejack/user_set'
  require 'supplejack/user_set_relation'
  require 'supplejack/user_story_relation'
  require 'supplejack/util'
end
