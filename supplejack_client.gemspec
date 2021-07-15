# frozen_string_literal: true

require File.expand_path('lib/supplejack/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Supplejack']
  gem.email         = ['info@digitalnz.org']
  gem.description   = ' Library to abstract the interaction with the Supplejack API '
  gem.summary       = ' Connects to the API, and allows you to treat models as if they were in a local database '
  gem.homepage      = 'http://digitalnz.org'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = 'supplejack_client'
  gem.require_paths = ['lib']
  gem.version       = Supplejack::VERSION

  gem.add_dependency 'rails', '~> 6.1.4'
  gem.add_dependency 'rails_autolink', '~> 1.0'
  gem.add_dependency 'rest-client', '~> 2.0'
  gem.add_dependency 'rubocop'

  gem.add_development_dependency 'codeclimate-test-reporter'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rspec', '~> 2.8'
end
