
alias k="kubectl"
alias kd="kubectl -n default"
alias klogs="kubectl logs"
alias kpods="kubectl get pods"
alias roxlogs="kubectl -n stackrox logs"
alias roxpods="kubectl -n stackrox get pods"
alias rox="kubectl -n stackrox"

set -gx KUBE_EDITOR "nvim"

# Cache kubectl completions — regenerate when kubectl is updated
if command -q kubectl
    set -l cache ~/.cache/kubectl-completions.fish
    set -l kubectl_path (command -s kubectl)
    if not test -f $cache; or test $kubectl_path -nt $cache
        kubectl completion fish > $cache
    end
    source $cache
end
