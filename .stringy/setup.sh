#!/bin/sh

sudo yum install -y git

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
git clone --bare https://github.com/stringy/configs $HOME/.cfg
config checkout
config config --local status.showUntrackedFiles no
