# frozen_string_literal: true

source 'http://rubygems.org'

# Specify your gem's dependencies in supplejack.gemspec
gemspec

gem 'pry'

group :development do
  if RUBY_VERSION >= '2.2.5'
    gem 'guard'
    gem 'guard-rspec'
  end
end

group :test do
  gem 'rubocop', require: false
  gem 'simplecov', require: false
end
