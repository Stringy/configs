#!/bin/bash

alias vup="vagrant up"
alias vdown="vagrant halt"

export _VAGRANT_ROOT="${HOME}/code/stringy/dev-tools/vagrant"

function vssh() {
    local name="$1"
    shift
    (cd "${_VAGRANT_ROOT}/${name}" && vagrant ssh -- "$@" )
}

function vcd() {
    cd "${_VAGRANT_ROOT}/${1}"
}

function vssh-add() {
    _ssh_add_if_not_exists "${_VAGRANT_ROOT}/${1}/.vagrant/machines/${2}/virtualbox/private_key"
}

function vagrant_complete() {
    [[ -d "${_VAGRANT_ROOT}" ]] || return
    COMPREPLY=($(cd "${_VAGRANT_ROOT}" && compgen -d))
}

complete -F vagrant_complete vssh
complete -F vagrant_complete vcd
complete -F vagrant_complete vssh-add
