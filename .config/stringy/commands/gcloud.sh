#!/bin/bash

source "$HOME/.config/stringy/common.sh"

function gcpssh() (
    PROJECT=$1
    HOST=$2
    shift;shift;
    _echo_and_run gcloud compute ssh $@ --project ${PROJECT} ${HOST}
)

function gcpscp() (
    PROJECT=$1
    FROM=$2
    TO=$3
    shift;shift;shift;
    _echo_and_run gcloud compute scp $@ --project ${PROJECT} ${FROM} ${TO}
)

function gcp-reload-ssh-config() {
    gcloud compute config-ssh --remove
    gcloud compute config-ssh
}

if [[ -e "${HOME}/.ssh/google_compute_engine" ]]; then
    _ssh_add_if_not_exists "${HOME}/.ssh/google_compute_engine"
fi
