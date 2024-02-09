# frozen_string_literal: true

require File.expand_path('lib/supplejack/version', __dir__)

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.0.3'
  spec.authors               = ['Supplejack']
  spec.email                 = ['info@digitalnz.org']
  spec.description           = ' Library to abstract the interaction with the Supplejack API '
  spec.summary               = ' Connects to the API, and allows you to treat models as if they were in a local database '
  spec.homepage              = 'http://digitalnz.org'

  spec.executables           = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.files                 = `git ls-files`.split("\n")
  spec.test_files            = `git ls-files -- spec/*`.split("\n")
  spec.name                  = 'supplejack_client'
  spec.require_paths         = ['lib']
  spec.version               = Supplejack::VERSION

  spec.add_dependency 'rails', '>= 7.1.0'
  spec.add_dependency 'rails_autolink', '~> 1.0'
  spec.add_dependency 'rest-client', '~> 2.0'

  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.22', '>= 1.22.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.4'
end
