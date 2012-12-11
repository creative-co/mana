set :application, 'application' #TODO: change this to application name

set :repository, 'git@github.com:author/application.git' #TODO: change this to repository

set :default_stage, :vagrant

# Uses Brightbox Next Generation Ruby Packages
# http://wiki.brightbox.co.uk/docs:ruby-ng
# by default.
# Change to specific version in ruby-build format
# if exact version needed.
set :ruby_version, :brightbox
set :care_about_ruby_version, false

set :postgresql, version: '9.1'

set :monit,
    notify_email: 'admin@application.com', #TODO: change this to your email to receive monit alerts
    poll_period: 30

set :run_list, %w(
  recipe[monit]
  recipe[monit::ssh]
  recipe[postgresql]
  recipe[nginx]
  recipe[railsapp]
)
  
after 'deploy:restart', 'deploy:restart_unicorn'
