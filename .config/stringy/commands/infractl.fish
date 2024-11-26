
alias infra-clr="rm -f $HOME/infra/*"
alias infra-dl="infractl artifacts --download-dir $HOME/infra"
alias infra-kconf="set -x KUBECONFIG $HOME/infra/kubeconfig"

complete -x --command infra-dl --arguments "(infractl list -q | awk '{\$1=\$1;print}')"
