
function docker-bash --description "Run bash in a given image"
    docker run -it --rm --entrypoint /bin/bash $argv
end

function docker-bash-priv --description "Run bash in a given image (privileged)"
    docker run -it --rm --privileged --entrypoint /bin/bash $argv
end

function docker-sh --description "Run sh in a given image"
    docker run -it --rm --entrypoint /bin/sh $argv
end

function docker-push-ghutton --description "Retag and push an image to ghutton quay repo"
    set -l image $argv[1]
    set -l name_and_tag (basename $image)

    docker tag $image quay.io/ghutton/$name_and_tag
    docker push quay.io/ghutton/$name_and_tag
end

alias docker-image-names="docker images --format '{{.Repository}}:{{.Tag}}'"

complete -x -c docker-bash --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-bash-priv --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-sh --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-push-ghutton --arguments "(docker-image-names | grep -v '<none>')"
