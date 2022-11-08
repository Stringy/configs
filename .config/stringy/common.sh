#!/bin/bash

export STRINGY_CONFIG_ROOT="${HOME}/.config/stringy"

alias vim=nvim

function _echo_and_run() {
    echo "[*]" $@
    eval $@
}

function _import_command_aliases() {
    if command -v ${1} &> /dev/null; then
        source "${STRINGY_CONFIG_ROOT}/commands/${1}.sh"
    fi
}

function _import_all_command_aliases() {
    for cmd in ${STRINGY_CONFIG_ROOT}/commands/*; do
        filename=$(basename -- "$cmd")
        command_name="${filename%.*}"
        _import_command_aliases "$command_name"
    done
}

function _ssh_add_if_not_exists() {
    if ssh-add -l | grep -q "$(ssh-keygen -lf "${1}" | awk '{print $2}')"; then
        return 0;
    else
        _echo_and_run ssh-add "${1}"
    fi
}

function cdme() {
    _echo_and_run cd "${HOME}/code/stringy"
}

function cdgo() {
    if [[ -z "${GOPATH}" ]]; then
        echo "[*] no GOPATH set"
        exit 1
    fi

    _echo_and_run cd "${GOPATH}/src/${1}"
}

function _cdme_complete() {
    [[ -d "${HOME}/code/stringy/" ]] || return
    COMPREPLY=($(cd "${HOME}/code/stringy/" && compgen -d))
}

complete -F _cdme_complete cdme
