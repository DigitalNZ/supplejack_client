# frozen_string_literal: true

require 'supplejack_client'
require 'rails'
require 'active_model'

# rubocop:disable Lint/SendWithMixinArgument
module Supplejack
  class Engine < Rails::Engine
    initializer 'supplejack.helpers' do
      ActionView::Base.send :include, Supplejack::Controllers::Helpers
      ActionController::Base.send :include, Supplejack::Controllers::Helpers
    end
  end
end
# rubocop:enable Lint/SendWithMixinArgument