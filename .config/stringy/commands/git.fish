
function git-rebase-progress
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
alias gsm="git switch (git_main_branch)"
alias gst="git status"
alias gss="git status -s"
alias gsubu="git submodule update --init"
alias gsubur="git submodule update --init --recursive"
alias gd="git diff"

alias gp="git pull"
alias gpf="git pull --ff-only"
alias gpu="git push -u origin (git rev-parse --abbrev-ref HEAD)"

function cdw --description "cd into a git worktree by name or fuzzy match"
    set -l repo_root (git_repo_root)
    or return 1

    set -l worktrees (git -C $repo_root worktree list --porcelain | string match 'worktree *' | string replace 'worktree ' '')

    if test (count $argv) -eq 0
        if command -q fzf
            set -l pick (printf '%s\n' $worktrees | fzf --prompt="Worktree: ")
            test -n "$pick"; and cd $pick
        else
            printf '%s\n' $worktrees
        end
        return
    end

    for wt in $worktrees
        if test (basename $wt) = "$argv[1]"
            cd $wt
            return
        end
    end

    set -l target (string lower -- $argv[1])
    for wt in $worktrees
        if string match -qi "*$target*" -- (basename $wt)
            cd $wt
            return
        end
    end

    echo "No worktree matching '$argv[1]'"
    return 1
end

complete -c cdw -f -a '(git worktree list --porcelain 2>/dev/null | string match "worktree *" | string replace "worktree " "" | xargs -I{} basename {})'

alias gr="git rebase"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias grm="git rebase (git_main_branch)"
