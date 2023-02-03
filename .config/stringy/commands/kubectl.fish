
alias klogs="kubectl logs"
alias kpods="kubectl get pods"
alias roxlogs="kubectl -n stackrox logs"
alias roxpods="kubectl -n stackrox get pods"

set -U KUBE_EDITOR "nvim"

source (kubectl completion fish | psub -f)
