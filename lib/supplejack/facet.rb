# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module Supplejack
  class Facet
    
    attr_reader :name
    
    def initialize(name, values)
      @name = name
      @values = values
    end

    def values(sort=nil)
      sort = sort || Supplejack.facets_sort

      array = case sort.try(:to_sym)
              when :index
                @values.sort_by {|k,v| k.to_s }
              when :count
                @values.sort_by {|k,v| -v.to_i }
              else
                @values.to_a
              end

      ActiveSupport::OrderedHash[array]
    end
  end
end
