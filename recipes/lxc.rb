### We need internet to install lxc!
### Because of it's dependencies... would like to fix that


# g++ and git required (because we use my fork with a fix for lxc-gem
['g++','git'].each do |p|
  t=package p do
    action :nothing
  end
  t.run_action :install
end
  
lxc_repo = ::File.join(Chef::Config['file_cache_path'],'lxc-ruby')
lxc_gem = ::File.join(lxc_repo,'lxc-0.1.0.gem')

if not ::File.exists? lxc_gem
  git_repo = git lxc_repo do
    repository "git://github.com/hh/lxc-ruby.git"
    reference "master"
    action :nothing
  end
  git_repo.run_action :sync

  gem_build = execute 'gem build lxc.gemspec' do
    cwd lxc_repo
    action :nothing
  end
  gem_build.run_action :run

end

chef_gem "lxc" do
  source lxc_gem
  action :install
end

require 'lxc'
