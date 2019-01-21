

source 'http://rubygems.org'

# Specify your gem's dependencies in supplejack.gemspec
gemspec

group :development do
  if RUBY_VERSION >= '2.2.5'
    gem 'guard'
    gem 'guard-rspec'
  end
  
  gem 'rubocop', require: false
end

group :test do
  gem 'simplecov', require: false
  gem 'rubocop', require: false
end
