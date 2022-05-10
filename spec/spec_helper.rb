# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'simplecov'

Bundler.require(:default)

require 'supplejack_client'
require 'active_support/all'

SimpleCov.start

RSpec.configure do |config|
  config.mock_with :rspec
  config.raise_errors_for_deprecations!
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = 'spec/examples.txt'
end
