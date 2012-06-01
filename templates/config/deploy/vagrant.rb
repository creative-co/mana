server '10.10.10.10', :web, :app, :db, primary: true

set :user, 'vagrant'
set :password, 'vagrant'

set :branch, 'master'
set :rails_env, 'production'
