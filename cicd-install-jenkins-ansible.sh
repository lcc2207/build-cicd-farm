#!/bin/bash
apt-get update; apt-get install -y python-pip git

# install ansible
pip install ansible==2.4.0

# clone repo
git clone https://github.com/lcc2207/scalr-jenkins-ansible.git
cd scalr-jenkins-ansible/

# pull down required ansible roles
ansible-galaxy install --roles-path . geerlingguy.jenkins

echo $jenkins_demo > ./vault

# execute the jenkins install playbook
ansible-playbook -i localhost jenkins.yml --vault-id ./vault

# fix issue with scarl-ctl
sudo -i -u jenkins scalr-ctl
