#!/bin/bash

set -e

function get_pkg_manager() {
    declare -A osInfo;
    osInfo[/etc/redhat-release]=yum
    osInfo[/etc/arch-release]=pacman
    osInfo[/etc/gentoo-release]=emerge
    osInfo[/etc/SuSE-release]=zypp
    osInfo[/etc/debian_version]=apt-get
    osInfo[/etc/alpine-release]=apk

    for f in ${!osInfo[@]}
    do
        if [[ -f "$f" ]];then
            echo "${osInfo[$f]}"
        fi
    done
}

function config() {
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

PKG="$(get_pkg_manager)"

sudo "${PKG}" install -y git ansible-core

git clone --bare https://github.com/stringy/configs $HOME/.cfg
config checkout
config config --local status.showUntrackedFiles no

ansible-galaxy collection install ansible.posix community.general

ansible-playbook ~/.stringy/ansible/dev-machine.yml
