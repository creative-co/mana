# Mana

Configuration management with Chef & Capistrano

## Installation

### Step 1

Add this line to your application's Gemfile:

    gem 'mana'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mana

### Step 2

Init project with Chef, Capistrano and Vagrant configs:

    rake mana:install

Edit `config/deploy.rb` to provide application name, SCM repository etc. and Chef cookbook params.

Edit `Vagrantfile` to match your available Vagrant boxes and personal taste.

Edit Chef cookbooks under `config/deploy/cookbooks` directory to add software.

## Usage

Setup all software on server:

    cap <stage> mana:setup

where `<stage>` is server name. Individual stages can be added in `config/deploy/` directory.
See default `vagrant` stage for details.

Use ordinary `cap deploy`-like stuff for later deploys and `cap mana:install` for configuration upgrades.

Use `cap -T mana` to see useful stuff added after this.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
