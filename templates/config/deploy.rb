#TODO: change this to application name
set :application, 'application'

#TODO: change this to repository
set :repository, 'git@github.com:author/application.git'

# set :deploy_subdir, ''

set :default_stage, :vagrant

# Uses Brightbox Next Generation Ruby Packages
# http://wiki.brightbox.co.uk/docs:ruby-ng
# by default.
# Change to specific version in ruby-build format
# if exact version needed.
#valid brightbox "1.9.3" and "2.0"
set :ruby_version, "2.0"
set :ruby_source, :brightbox
set :care_about_ruby_version, false

set :postgresql,
    version: '9.1',
    listen_all: false #TODO: changes this to `true` for TCP connectivity

set :monit,
    notify_email: 'admin@application.com', #TODO: change this to your email to receive monit alerts
    poll_period: 30

set :railsapp,
    server_names: '_' #TODO: change this to domain name(s) of the project

set :aws,
    access_key_id: '',
    secret_access_key: '' #TODO: set this to let railsapp::backup put backups in s3

# For other options look into cookbooks/*/attributes/default.rb
# and other cookbook sources.

set :run_list, %w(
  recipe[monit]
  recipe[monit::ssh]
  recipe[postgresql]
  recipe[nginx]
  recipe[railsapp]
  recipe[railsapp::backup]
)
  
after 'deploy:restart', 'deploy:restart_unicorn'
