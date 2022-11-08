#!/bin/bash

function docker-bash() {
    docker run -it --rm --entrypoint bash ${1}
}

