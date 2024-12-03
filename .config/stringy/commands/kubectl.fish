
alias k="kubectl"
alias klogs="kubectl logs"
alias kpods="kubectl get pods"
alias roxlogs="kubectl -n stackrox logs"
alias roxpods="kubectl -n stackrox get pods"
alias rox="kubectl -n stackrox"

set -gx KUBE_EDITOR "nvim"

if type -q "kubectl";
    source (kubectl completion fish | psub)
end

