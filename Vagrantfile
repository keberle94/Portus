# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  
  config.vm.define :portus do |node|
    node.vm.box = "flavio/opensuse13-2"
    node.vm.box_check_update = true
    node.vm.network :private_network, ip: "192.168.1.3", virtualbox__intnet: true
    node.vm.network "forwarded_port", guest: 80, host: 3000
    node.vm.provision "shell", inline: <<EOS
zypper -n in tcpdump

zypper -n in apache2-devel \
  gcc \
  gcc-c++ \
  git-core \
  libcurl-devel \
  libmysqlclient-devel \
  libopenssl-devel \
  libstdc++-devel \
  libxml2-devel \
  libxslt-devel \
  make \
  mariadb \
  nodejs \
  patch \
  ruby2.1-devel \
  rubygem-bundler \
  zlib-devel

zypper ar -f http://download.opensuse.org/repositories/devel:/openQA/openSUSE_13.2/ phantomjs
zypper --gpg-auto-import-keys ref

zypper -n in phantomjs

systemctl enable mysql
systemctl start mysql

cd /vagrant
bundle config build.nokogiri --use-system-libraries
bundle install
bundle exec rake db:create
bundle exec rake db:migrate

sudo gem install passenger -v 5.0.7
passenger-install-apache2-module.ruby2.1 -a

cp /vagrant/vagrant/conf/portus/sysconfig_apache2 /etc/sysconfig/apache2
cp /vagrant/vagrant/conf/portus/httpd.conf.local /etc/apache2/httpd.conf.local
cp /vagrant/vagrant/conf/portus/portus.test.lan.conf /etc/apache2/vhosts.d/

systemctl enable apache2
EOS
  end
end
