
set -gx CONTAINER_CONNECTION dev
#set -gx DOCKER_CONTEXT dev

alias podman-login="podman login --authfile $HOME/.config/containers/auth.json"

alias postgres-dev="podman run --rm --env POSTGRES_USER=$USER --env POSTGRES_HOST_AUTH_METHOD=trust --network host docker.io/library/postgres:13"
