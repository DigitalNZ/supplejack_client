# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rubygems'
require 'bundler/setup'
require 'simplecov'

Bundler.require(:default)

require 'supplejack_client'
require 'active_support/all'

SimpleCov.start

RSpec.configure do |config|
  # some (optional) config here
  config.mock_with :rspec
  
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
