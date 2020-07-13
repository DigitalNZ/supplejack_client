# frozen_string_literal: true

source 'http://rubygems.org'

# Specify your gem's dependencies in supplejack.gemspec
gemspec

group :development do
  if RUBY_VERSION >= '2.2.5'
    gem 'guard'
    gem 'guard-rspec'
  end
end

group :test do
  gem 'rubocop', require: false
  gem 'rubocop-rails', '2.5.0', require: false
  gem 'simplecov', require: false
end
