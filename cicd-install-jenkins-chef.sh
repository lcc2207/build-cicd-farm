#!/bin/bash
OS=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}')

if [ $OS == "CentOS" ]
then
  yum update -y
  yum install git wget -y

  # download ChefDK
  cd /tmp/
  wget https://packages.chef.io/files/stable/chefdk/3.3.23/el/7/chefdk-3.3.23-1.el7.x86_64.rpm

  # install chefdk
  yum install -y /tmp/chefdk-3.3.23-1.el7.x86_64.rpm

elif [ $OS == "Ubuntu" ]
then
  apt update
  apt install git wget -y

  # download ChefDK
  cd /tmp/
  wget https://packages.chef.io/files/stable/chefdk/3.3.23/ubuntu/16.04/chefdk_3.3.23-1_amd64.deb

  # install chefdk
  dpkg -i /tmp/chefdk_3.3.23-1_amd64.deb
fi

# make cookbooks and data_bags folders
mkdir -p /tmp/cookbooks/
mkdir -p /tmp/data_bags/

# clone the cookbook
cd /tmp/cookbooks/
git clone https://github.com/lcc2207/scalr-jenkins.git

# resolve depends
cd scalr-jenkins/
cp -R ./test/integration/data_bags/* /tmp/data_bags/
berks vendor ../
cd /tmp

# make chef run
chef-client -z -o scalr-jenkins
