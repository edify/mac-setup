#!/bin/bash

if [ ! -f /usr/local/bin/brew ]; then
	#Install homebrew
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

#No password sudo
sudo sed -i .bak -e 's/^# \(%wheel.*ALL=(ALL) NOPASSWD: ALL\)/\1/g' /etc/sudoers
sudo dscl . append /Groups/wheel GroupMembership $USER

brew install ansible

#Run Ansible
ansible-playbook desktop.yml

#Delete src folder
rm -rf ~/src

#Return to normal password sudo
sudo sed -i .bak -e 's/^\(%wheel.*ALL=(ALL) NOPASSWD: ALL\)/# \1/g' /etc/sudoers
sudo dscl . delete /Groups/wheel GroupMembership $USER
