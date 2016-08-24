# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a Supplejack Client initializer."

      def copy_initializer
        template "supplejack_client.rb", "config/initializers/supplejack_client.rb"
      end

      def copy_locale
        copy_file "../locales/en.yml", "config/locales/supplejack_client.en.yml"
      end

      def show_readme
        readme "README"
      end
    end
  end
end