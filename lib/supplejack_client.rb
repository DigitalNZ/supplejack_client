# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'supplejack/config'
require 'supplejack/version'

module Supplejack
  extend Config
  
  require 'supplejack/engine'
  require 'supplejack/exceptions'
  require 'supplejack/log_subscriber'
  require 'supplejack/record'
  require "supplejack/request"
  # require 'supplejack/favourites_list'
  require 'supplejack/paginated_collection'
  require 'supplejack/controllers/helpers'
  # require 'supplejack/controllers/favourite_helpers'
  require 'supplejack/url_formats/item_hash'
  require 'supplejack/util'
  # require 'supplejack/ucm_relation'
  # require 'supplejack/ucm_record'
  # require 'supplejack/authority'
  require 'supplejack/facet'
  # require 'supplejack/attachment'
  # require 'supplejack/user_set'
  # require 'supplejack/item_relation'
  # require 'supplejack/item'
  require 'supplejack/user'
  # require 'supplejack/user_set_relation'
end
