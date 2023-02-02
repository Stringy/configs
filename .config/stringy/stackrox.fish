
if test -f $HOME/.infra
    set -gx INFRA_TOKEN (cat $HOME/.infra | cut -d '=' -f2)
end

function push-collector-ghutton --description "Push the current collector image to my repository"
    docker tag quay.io/stackrox-io/collector:(make tag) quay.io/ghutton/collector:test
    docker push quay.io/ghutton/collector:test
end

function cdrox --description "cd into a ROX directory" --wraps "cd $GOPATH/src/github.com/stackrox/"
    cd $GOPATH/src/github.com/stackrox/$argv[1]
end

#complete --command cdrox -F --arguments "(complete_in_dir $GOPATH/src/github.com/stackrox/)"
