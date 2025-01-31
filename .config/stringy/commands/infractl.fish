
alias infra-kconf="set -x KUBECONFIG $HOME/infra/kubeconfig"


set -gx INFRA_ROOT_DIR "$HOME/infra"

function infra-dl --description "Download configuration for an infra cluster"
    set -l infra_name $argv[1]

    if ! test -d "$INFRA_ROOT_DIR/$infra_name"
        mkdir "$INFRA_ROOT_DIR/$infra_name"
    end

    echo "[*] downloading aritfacts for $infra_name"
    infractl artifacts --download-dir "$INFRA_ROOT_DIR/$infra_name" $infra_name
end

function infra-clr --description "Remove a cluster configuration or all configurations"
    if count $argv >/dev/null
        rm -rf "$INFRA_ROOT_DIR/$argv[1]"
    else
        rm -rf "$INFRA_ROOT_DIR/*"
    end
end

function infra-switch --description "Switch kubeconfig to a given cluster"
    set -l config "$INFRA_ROOT_DIR/$argv[1]/kubeconfig"

    if ! test -f $config
        echo "[*] cluster configuration doesn't exist"
        infra-dl $argv[1]
    end

    echo "[*] setting KUBECONFIG=$config"
    set -gx KUBECONFIG "$config"
end

complete -x --command infra-dl --arguments "(infractl list -q | awk '{\$1=\$1;print}')"
complete -x --command infra-clr --arguments "(infractl list -q | awk '{\$1=\$1;print}')"
complete -x --command infra-switch --arguments "(infractl list -q | awk '{\$1=\$1;print}')"

alias idl=infra-dl
alias iclr=infra-clr
alias is=infra-switch
