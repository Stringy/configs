
function git-rebase-progress
    # ( RMD="$( git rev-parse --git-path 'rebase-merge/' )" && N=$( cat "${RMD}msgnum" ) && L=$( cat "${RMD}end" ) && echo "${N} / ${L}" ; )
    # https://stackoverflow.com/a/57292015
    set -l rmd (git rev-parse --git-path 'rebase-merge/')
    set -l n (cat $rmd"msgnum")
    set -l l (cat $rmd"end")
    echo "$n / $l"
end

alias g="git"
alias ga="git add"
alias gap="git add -p"
alias gb="git branch"
alias gc="git commit -v"
alias gc!="git commit -v --amend"
alias gs="git switch"
alias gsc="git switch -c"
alias gsm="git switch (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
alias gst="git status"
alias gss="git status -s"
alias gsubu="git submodule update --init"
alias gsubur="git submodule update --init --recursive"

