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

function _collector_tag
    pushd $STACKROX_ROOT/collector
    make tag
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

function collector-clone --description "clone collector repository into GOPATH"
    argparse h/https -- $argv

    if test -d $GOPATH/src/github.com/stackrox/collector
        echo "Collector already cloned!"
        return 1
    end

    if not test -d $GOPATH/src/github.com/stackrox
        mkdir -p $GOPATH/src/github.com/stackrox
    end

    set -l fish_trace 1
    if set -q _flag_h
        git clone --recursive https://github.com/stackrox/collector.git $GOPATH/src/github.com/stackrox/collector
    else
        git clone --recursive git@github.com:stackrox/collector.git $GOPATH/src/github.com/stackrox/collector
    end
end

function collector-standalone --description "run the collector image standalone"
    set -q COLLECTOR_TAG || set -l COLLECTOR_TAG (_collector_tag)

    set -x COLLECTOR_CONFIG '{"logLevel":"debug"}'

    docker run -it --rm \
        --privileged \
        --name collector \
        --network=host \
        -v /proc:/host/proc:ro \
        -v /etc:/host/etc:ro \
        -v /usr/lib:/host/usr/lib:ro \
        -v /sys/kernel/debug:/host/sys/kernel/debug:ro \
        -v /tmp:/tmp \
        -v /module \
        -e COLLECTION_METHOD=core-bpf \
        -e COLLECTOR_CONFIG \
        "quay.io/stackrox-io/collector:$COLLECTOR_TAG"
end

function collector-clear-logs --description "clear collector logs"
    rm -f "$STACKROX_ROOT/collector/integration-tests/container-logs/core-bpf/*"
end

function rox-teardown
    kubectl get pv -o json | jq -r '.items[] | select(.spec.claimRef.namespace == "stackrox") | .metadata.name' | IFS='\n' read -d '' -r -a stackrox_pvs
    kubectl -n stackrox delete --grace-period=0 --force deploy/central deploy/sensor ds/collector deploy/monitoring statefulsets/stackrox-monitoring-alertmanager
    kubectl -n stackrox get application -o name | xargs kubectl -n stackrox delete --wait
    # MUST be namespaced, otherwise you delete a lot of stuff
    kubectl -n stackrox get cm,deploy,ds,hpa,networkpolicy,role,rolebinding,secret,svc,serviceaccount,pvc -o name | xargs kubectl -n stackrox delete --wait
    # Only delete cluster-wide RBAC/PSP-related resources that contain have the app.kubernetes.io/name=stackrox label.
    kubectl -n stackrox get clusterrole,clusterrolebinding,psp,validatingwebhookconfiguration -o name -l app.kubernetes.io/name=stackrox | xargs kubectl -n stackrox delete --wait

    if test (count $stackrox_pvs) -ne 0
        kubectl delete --wait pv $stackrox_pvs
    end

    if kubectl api-versions | grep -q openshift.io
        for scc in central monitoring scanner sensor stackrox-central stackrox-monitoring stackrox-scanner stackrox-sensor stackrox-central-db
            oc delete scc $scc
        end

        oc delete route central -n stackrox
        oc delete route central-mtls -n stackrox
        oc -n kube-system get rolebinding -o name -l app.kubernetes.io/name=stackrox | xargs oc -n kube-system delete --wait
        oc -n openshift-monitoring get prometheusrule,servicemonitor -o name -l app.kubernetes.io/name=stackrox | xargs oc -n openshift-monitoring delete --wait
    end
end
