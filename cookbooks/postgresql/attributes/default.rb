default[:postgresql][:version] = "9.1"
default[:postgresql][:ssl] = true
default[:postgresql][:listen_all] = false

set[:postgresql][:dir] = "/etc/postgresql/#{node[:postgresql][:version]}/main"
