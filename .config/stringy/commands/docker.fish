
function docker-bash --description "run bash in a given image"
    argparse h/help -- $argv

    if set -ql _flag_help
        echo "docker-bash [-h|--help] <image>"
        return 0
    end

    docker run -it --rm --entrypoint bash $argv[1]
end

function docker-push-ghutton --description "Retag and push an image for ghutton quay repo"
    set -l image $argv[1]

    set -l name_and_tag (basename $image)

    docker tag $image quay.io/ghutton/$name_and_tag
    docker push quay.io/ghutton/$name_and_tag
end

function docker-push-collector-ghutton --description "Push the latest collector image"
    set -l tag (cd $GOPATH/src/github.com/stackrox/collector && make tag)
    docker-push-ghutton quay.io/stackrox-io/collector:$tag
end

alias docker-image-names="docker images --format '{{.Repository}}:{{.Tag}}'"

complete -x -c docker-bash --arguments "(docker-image-names | grep -v '<none>')"
complete -x -c docker-push-ghutton --arguments "(docker-image-names | grep -v '<none>')"
