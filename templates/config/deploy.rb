set :application, 'application' #TODO: change this to application name

set :repository, 'git@github.com:author/application.git' #TODO: change this to repository

set :default_stage, :vagrant

set :ruby_version, '1.9.3-p194'

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
