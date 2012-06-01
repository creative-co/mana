default[:railsapp][:server_names] = "_"

default[:railsapp][:ssl] = false
default[:railsapp][:ssl_crt_path] = nil
default[:railsapp][:ssl_key_path] = nil

default[:railsapp][:db_name] = "#{node[:application]}_#{node[:rails_env]}"

default[:railsapp][:worker_processes] = 4
default[:railsapp][:request_timeout] = 60
default[:railsapp][:worker_user]  = 'nobody'
default[:railsapp][:worker_group] = 'nogroup'

default[:railsapp][:before_fork] = <<-RUBY
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
  Resque.redis.quit if defined?(Resque)
RUBY

default[:railsapp][:after_fork] = <<-RUBY
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  Resque.redis = Redis.connect if defined?(Resque)
RUBY
