#!/bin/bash

if [ -e "$HOME/.infra" ]; then
    . "$HOME/.infra"
fi

if [ -e "$HOME/code/go/src/github.com/stackrox/workflow/env.sh" ]; then
    source "$HOME/code/go/src/github.com/stackrox/workflow/env.sh"
fi

function push-collector-ghutton() {
    docker tag "quay.io/stackrox-io/collector:$(make tag)" quay.io/ghutton/collector:test
    docker push quay.io/ghutton/collector:test
}
