default['virtualization']['qemu']['vnc_listen'] = "0.0.0.0"
default['virtualization']['lxc']['network_link'] = "lxcbr0"

default['virtualization']['network'] = '10.12.13'
default['virtualization']['domain'] = node['resolver']['search'] || 'foglab'
default['virtualization']['hostip'] = "#{node['virtualization']['network']}.1"

default['virtualization']['lxc']['addr'] = "#{node['virtualization']['network']}.1"
default['virtualization']['lxc']['netmask'] = "255.255.255.0"
default['virtualization']['lxc']['network'] = "#{node['virtualization']['network']}.0/24"
default['virtualization']['lxc']['dhcp_start'] = '2'
default['virtualization']['lxc']['dhcp_stop'] = '254'
default['virtualization']['lxc']['dhcp_range'] = "#{node['virtualization']['network']}.#{node['virtualization']['lxc']['dhcp_start']},#{node['virtualization']['network']}.#{node['virtualization']['lxc']['dhcp_stop']}"
default['virtualization']['lxc']['dhcp_max'] = node['virtualization']['lxc']['dhcp_stop'].to_i - node['virtualization']['lxc']['dhcp_start'].to_i 

# /var/lib/lxc is a bit too transient
# since it is hardcoded everywhere, we symlink it to other places if desired
default['virtualization']['lxc']['path']='/home/lxc'
default['virtualization']['lxc']['default_path']='/var/lib/lxc'

