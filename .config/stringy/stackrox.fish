set -gx STACKROX_ROOT $GOPATH/src/github.com/stackrox

if test -f $HOME/.infra
    set -gx INFRA_TOKEN (cat $HOME/.infra | cut -d '=' -f2)
end

function push-collector-ghutton --description "Push the current collector image to my repository"
    docker tag quay.io/stackrox-io/collector:(make tag) quay.io/ghutton/collector:test
    docker push quay.io/ghutton/collector:test
end

function cdrox --description "cd into a ROX directory"
    cd $STACKROX_ROOT/$argv[1]
end

complete -x --command cdrox --arguments "(complete_in_dir $STACKROX_ROOT)"
