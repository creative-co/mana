directory node[:deploy_to] do
  mode 0775
  owner node[:user]
  action :create
end

directory node[:shared_path] do
  mode 0775
  owner node[:user]
  action :create
end

directory "#{node[:shared_path]}/sockets" do
  mode 0775
  owner node[:user]
  action :create
end

template "#{node[:shared_path]}/unicorn.rb" do
  source "unicorn.rb.erb"
  owner "root"
  group "root"
  mode 0644
end

gem_package "bundler"

bash "create_database" do
  code "psql -U postgres -c \"create database #{node[:railsapp][:db_name]}\""
  only_if "test `psql -At -U postgres -c \"select count(*) from pg_database where datname = '#{node[:railsapp][:db_name]}';\"` -eq 0"
end

template "#{node[:nginx][:dir]}/sites-available/#{node[:application]}" do
  source "site.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, "service[nginx]"
end

template "/etc/init.d/#{node[:application]}-web" do
  source "unicorn-init.sh.erb"
  owner "root"
  group "root"
  mode 0755
end

nginx_site 'default' do
  enable false
end

nginx_site node[:application] do
  enable true
end

monitrc "#{node[:application]}-web" do
  source "master.monit.conf.erb"
end

node[:railsapp][:worker_processes].times do |i|
  monitrc "#{node[:application]}-web-#{i}" do
    source "worker.monit.conf.erb"
    variables nr: i
  end
end
