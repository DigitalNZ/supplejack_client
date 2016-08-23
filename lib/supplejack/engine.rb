# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'supplejack_client'
require 'rails'
require 'active_model'

module Supplejack
  class Engine < Rails::Engine

    initializer "supplejack.helpers" do
      ActionView::Base.send :include, Supplejack::Controllers::Helpers
      ActionController::Base.send :include, Supplejack::Controllers::Helpers
    end

  end
end