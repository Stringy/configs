#!/bin/bash

set -e

sudo yum install -y git ansible-core

function config() {
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
git clone --bare https://github.com/stringy/configs $HOME/.cfg
config checkout
config config --local status.showUntrackedFiles no

ansible-galaxy collection install ansible.posix

ansible-playbook ~/.stringy/ansible/dev-machine.yml
