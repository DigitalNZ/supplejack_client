# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_autolink'

module Supplejack
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      def search(special_params=nil)
        return @supplejack_search if @supplejack_search
        klass = Supplejack.search_klass ? Supplejack.search_klass.classify.constantize : Supplejack::Search
        @supplejack_search = klass.new(special_params || params[:search] || params)
      end

    end
  end
end
