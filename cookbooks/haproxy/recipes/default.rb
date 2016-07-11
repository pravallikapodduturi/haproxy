
# Cookbook Name:: haproxy
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

execute "apt-get update"

package "haproxy" do
  action :install
end


pool_members = search("node", "chef_environment:#{node.chef_environment} AND role:web") || []

pool_members.map! do |member|
  {:ipaddress => member['ipaddress'], :hostname => member['hostname']}
end

if pool_members.length > 0

  http_clients = pool_members.uniq.map do |s|
    "server #{s[:hostname]} #{s[:ipaddress]}:80 weight 1 maxconn 1024 check"
  end
  http_clients = ["mode http"] + http_clients + ["option httpchk GET /healthcheck"]

  https_clients = pool_members.uniq.map do |s|
    "server #{s[:hostname]} #{s[:ipaddress]}:443 weight 1 maxconn 1024 check"
  end
  https_clients = ["mode http"] + https_clients + ["option httpchk GET /ssl-healthcheck"]

else

  http_clients = https_clients = []

end

listeners = {
  "listen" => {},
  "frontend" => {
    "ft_http" => [
      "bind *:80",
      "mode tcp",
      "default_backend bk_http"
    ],
    "ft_https" => [
      "bind *:443",
      "mode tcp",
      "default_backend bk_https"
    ]
  },
  "backend" => {
    "bk_http" => http_clients,
    "bk_https" => https_clients
  }
}

template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 00644
  #notifies :reload, 'service[haproxy]'
  variables(
    :listeners => listeners
  )
  notifies :reload, "service[haproxy]"
end

cookbook_file '/etc/default/haproxy' do
  source 'haproxy-default'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[haproxy]'
end


service 'haproxy' do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end
