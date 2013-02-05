#
# Cookbook Name:: virtualization
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


# chef_gem 'lxc' do
# Mayb need to put this inside the cookbook 8(
# end

package "python-vm-builder"

package "virtinst"

include_recipe "ii-lxc::lxc"

# Because ubuntu starts services by default when you install a package,
# the configs must be inplace before we install lxc,
template "/etc/default/lxc" do
  source "lxc.erb"
  owner "root"
  group "root"
  mode "0644"
end

# as lxc-net autostarts and we want to call dnsmasq with special parms
template "/etc/init/lxc-net.conf" do
  source "lxc-net.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  #  notifies :restart, "service[lxc-net]" # Service isn't installed yet
end

# dnsmasq is called from network-manager
if ::File.exists? '/etc/init.d/network-manager'
  service "network-manager" do
    action :nothing
  end
end

# and we want dnsmasq command line modified to point to lxc-dnsmasq for
# the .local and .training domains etc
# so the host OS can reach the containers / virtualboxes
template "/usr/local/sbin/dnsmasq" do
  source "dnsmasq.erb"
  owner "root"
  group "root"
  mode "0755"
  if ::File.exists? '/etc/init.d/network-manager'
    notifies :restart, 'service[network-manager]', :immediately # dnsmasq will now point to us
  end
end

# Restarting network manager makes the install of lxc fail due to network issues
# so we added some retries

# The extra options are to make sure it doesn't prompt regarding modified configs
# ie /etc/default/lxc and /etc/init/lxc-net.conf
package "lxc" do
  options '--force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'
  retries 12 # retry 12 times... 
  retry_delay 20 # once every 20 seconds.. for four minutes
end

# In order to change the default lxc path,
# we must delete the default directory
# and symlink to the new one

def_lxc_path = node['virtualization']['lxc']['default_path']
lxc_path = node['virtualization']['lxc']['path']

if lxc_path != def_lxc_path
  # Maybe we should look at moving it?
  directory def_lxc_path do
    action :delete
    not_if {::File.symlink? def_lxc_path}
  end
  
  directory lxc_path
  
  link def_lxc_path do
    to lxc_path
  end
end

package "novnc"

template "/etc/libvirt/qemu.conf" do
  source "qemu.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "/etc/lxc/lxc.conf" do
  source "lxc.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

execute "ssh-keygen  -q -f /etc/lxc/ssh_id_rsa -P '' -C 'lxc-ssh-key'" do
  not_if {File.exists? "/etc/lxc/ssh_id_rsa.pub"}
end

template "/usr/lib/lxc/templates/lxc-training" do
  source "lxc-training.erb"
  owner "root"
  group "root"
  mode "0755"
end

# centos package requires yum
package 'yum'

template "/usr/lib/lxc/templates/lxc-centos" do
  source "lxc-centos.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/usr/local/bin/kvm-setup" do
  source "kvm-setup.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/usr/local/bin/training-setup" do
  source "training-setup.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "/usr/local/bin/training-destroy" do
  source "training-destroy.erb"
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "/usr/local/bin/ziprepos" do
  source "ziprepos"
  owner "root"
  group "root"
  mode "0755"
end

service "lxc-net" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true
  action [:enable, :start]
end


# we use the hosts_entry definition from hosts cookbook
# it drives template[/etc/hosts]
# all dns masq processes must be notified to re-read the file
execute 'reload dnsmasq' do
  command 'killall -HUP dnsmasq || true'
  action :nothing
  subscribes :run, 'template[/etc/hosts]', :immediately #resources(template: '/etc/hosts')
end

hosts_entry "traininglaptop.#{node['virtualization']['domain']}" do
  ip node['virtualization']['hostip']
  aliases [
    "laptop.#{node['virtualization']['domain']}",
    "laptop",
    "fileserver.#{node['virtualization']['domain']}"
    # "packages.medibuntu.org" # no way to reach this via IP
  ]
end

service "procps" do
  action :nothing
end

file "/etc/sysctl.d/60-lxc.conf" do
  content <<-EOF
# we do a lot of natting
net.netfilter.nf_conntrack_max = 512000
# needs to be increased once everyone starts apt-get installing at the same time
# maybe 50 times as large as the default?
sysctl fs.filemax = 5000000 
  EOF
  notifies :start, 'service[procps]', :immediately
end
