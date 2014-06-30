# Supplejack Client

The Supplejack Client is a library to abstract the interaction with the Supplejack API. It connects to the Supplejack API, and allows you to treat models as if they were in a local database.

For more information on how to configure and use this application refer to the [documentation](http://digitalnz.github.io/supplejack).

## Installation

Add it to your Gemfile:

```ruby
gem 'supplejack_client', github: 'git@github.com:DigitalNZ/supplejack_client.git'
```

Run bundle install:

```ruby
bundle install
```

Run the installation generator:

```ruby
rails g supplejack:install
```

An initializer was created at config/initializers/supplejack_client.rb

You should set the variables needed by the Supplejack API:
- Api Key
- Api URL

To start using Supplejack gem you have add the following line to any plain ruby class

class Item
  include Supplejack::Record
end

Then do Search.new(params) or Item.find(id)
