set -gx STACKROX_ROOT $GOPATH/src/github.com/stackrox
set -gx COLLECTOR_MODULES_BUCKET gs://collector-modules-osci
set -gx COLLECTOR_SUPPORT_PKG_BUCKET gs://collector-support-public/offline/v1/support-packages

if test -f $HOME/.infra
    set -gx INFRA_TOKEN (cat $HOME/.infra | cut -d '=' -f2)
end

function push-collector-ghutton --description "Push the current collector image to my repository"
    docker tag quay.io/stackrox-io/collector:(make tag) quay.io/ghutton/collector:test
    docker push quay.io/ghutton/collector:test
end

function cdrox --description "cd into a ROX directory"
    if count $argv >/dev/null
        cd $STACKROX_ROOT/$argv[1]
    else
        cd $STACKROX_ROOT/stackrox
    end
end

function _collector_module_version
    pushd $STACKROX_ROOT/collector
    cat kernel-modules/MODULE_VERSION 2>/dev/null
    popd
end

function check-collector-drivers --description "look up built drivers"
    argparse m/module-version= -- $argv

    if count $argv >/dev/null
        if set -ql _flag_m
            set -f bucket $COLLECTOR_MODULES_BUCKET/$_flag_m
        else
            set -f bucket $COLLECTOR_MODULES_BUCKET/(_collector_module_version)
        end

        echo "[*] Searching $bucket" 1>&2
        set -l modules (gsutil ls $bucket 2>/dev/null | grep $argv[1])
        printf '%s\n' $modules
    else
        echo "[*] provide a kernel version to search for."
    end
end

function check-support-packages --description "lookup the support packages"
    argparse m/module-version= a/arch= -- $argv

    if set -ql _flag_a
        set -f bucket $COLLECTOR_SUPPORT_PKG_BUCKET/$_flag_a
    else
        set -f bucket $COLLECTOR_SUPPORT_PKG_BUCKET/x86_64
    end

    if set -ql _flag_m
        set -f bucket $bucket/$_flag_m
    else
        set -f bucket $bucket/(_collector_module_version)
    end

    echo "[*] Searching $bucket" 1>&2
    set -l pkgs (gsutil ls $bucket 2>/dev/null)
    printf '%s\n' $pkgs
end

function latest-support-package --description "get the latest support package"
    argparse m/module-version= a/arch= -- $argv

    set -q _flag_m or set -l _flag_m (_collector_module_version)
    set -q _flag_a or set -l _flag_a x86_64

    check-support-packages --module-version=$_flag_m --arch=$_flag_a |\
        sort | tail -n4 | head -n1 | \
        sed "s|^$COLLECTOR_SUPPORT_PKG_BUCKET/||"
end

complete -x --command cdrox --arguments "(complete_in_dir $STACKROX_ROOT)"

alias cdc='cdrox collector'
