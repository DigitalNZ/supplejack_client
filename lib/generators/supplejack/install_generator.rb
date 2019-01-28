# frozen_string_literal: true

module Supplejack
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates a Supplejack Client initializer.'

      def copy_initializer
        template 'supplejack_client.rb', 'config/initializers/supplejack_client.rb'
      end

      def copy_locale
        copy_file '../locales/en.yml', 'config/locales/supplejack_client.en.yml'
      end

      def show_readme
        readme 'README'
      end
    end
  end
end
