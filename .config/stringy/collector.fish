
function collector-test --description "Run collector test"
    argparse 'h/help' 'f/full' 't/test=' 'v/version=' -- $argv

    if set -q _flag_h
        echo "Usage: collector-test [OPTIONS]"
        echo " -h/--help    Print usage"
        echo " -f/--full    Use full image tag (append -full to the tag)"
        echo " -t/--test    Set the test to run (defaults to ci-integration-tests)"
        echo " -v/--version Set the collector version to use (the image tag)"
        return 0
    end

    set -l collector_dir $GOPATH/src/github.com/stackrox/collector
    set -l test_dir $collector_dir/integration-tests

    if not test -d $test_dir
        echo "$test_dir directory does not exist!"
    end

    set -l tag_suffix
    if set -q _flag_f
        set tag_suffix "-full"
    end

    if test -z "$_flag_v"
        set _flag_v (make --no-print-directory -C $collector_dir tag)
    end

    if test -z "$_flag_t"
        set _flag_t ci-integration-tests
    end

    set -lx COLLECTOR_IMAGE "quay.io/stackrox-io/collector:$_flag_v$tag_suffix"
    echo "COLLECTOR_IMAGE=$COLLECTOR_IMAGE"
    set -l fish_trace 1
    make -C $test_dir $_flag_t $argv
end
