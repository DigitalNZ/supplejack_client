# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# -*- encoding: utf-8 -*-
require File.expand_path('../lib/supplejack/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Supplejack']
  gem.email         = ['info@digitalnz.org']
  gem.description   = %q{ Library to abstract the interaction with the Supplejack API }
  gem.summary       = %q{ Connects to the API, and allows you to treat models as if they were in a local database }
  gem.homepage      = 'http://digitalnz.org'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = 'supplejack_client'
  gem.require_paths = ['lib']
  gem.version       = Supplejack::VERSION
  
  if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("2.2.2")
    gem.add_dependency 'rails', '>= 3.2.12', '< 5.0'
  else
    gem.add_dependency 'rails', '>= 3.2.12'
  end
  
  gem.add_dependency 'rest-client', '~> 1.6'
  gem.add_dependency 'rails_autolink', '~> 1.0'
  
  gem.add_development_dependency 'rspec', '~> 2.8'
  gem.add_development_dependency 'codeclimate-test-reporter'
  gem.add_development_dependency 'pry'
end
