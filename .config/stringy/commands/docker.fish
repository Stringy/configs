
function docker-bash --description "run bash in a given image"
    argparse h/help -- $argv

    if set -ql _flag_help
        echo "docker-bash [-h|--help] <image>"
        return 0
    end

    docker run -it --rm --entrypoint /bin/bash $argv[1]
end

function docker-sh --description "run bash in a given image"
    argparse h/help -- $argv

    if set -ql _flag_help
        echo "docker-bash [-h|--help] <image>"
        return 0
    end

    docker run -it --rm --entrypoint /bin/sh $argv[1]
end

function docker-push-ghutton --description "Retag and push an image for ghutton quay repo"
    set -l image $argv[1]

    set -l name_and_tag (basename $image)

    docker tag $image quay.io/ghutton/$name_and_tag
    docker push quay.io/ghutton/$name_and_tag
end

function docker-push-collector-ghutton --description "Push the latest collector image"
    set -l tag (cd $GOPATH/src/github.com/stackrox/collector && make tag)
    docker tag quay.io/stackrox-io/collector:$tag quay.io/ghutton/collector:test
    docker push quay.io/ghutton/collector:test
end

function docker-update-ssh-context --description "Updates the address of an SSH-based context"
    set -l address $argv[1]
    set -l context $argv[2]

    docker context update --docker host="ssh://$address" $context
end

alias docker-image-names="docker images --format '{{.Repository}}:{{.Tag}}'"

complete -x -c docker-bash --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-sh --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-push-ghutton --arguments "(docker-image-names | grep -v '<none>')"
