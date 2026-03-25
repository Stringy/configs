
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'

alias fvim="fzf --bind 'enter:become(vim {})'"
alias dvim="fd . --type d | fvim"

function repos -d "Fuzzy-find and cd into a repo"
    set -l dir (fd . $GOPATH/src/github.com $HOME/code --type d --max-depth 3 --min-depth 1 | fzf)
    test -n "$dir"; and cd $dir
end

function fco -d "Fuzzy-find and checkout a branch" --argument-names branch
    set -q branch[1]; or set branch ''
    git for-each-ref --format='%(refname:short)' refs/heads \
        | fzf --height 10% --layout=reverse --border --query=$branch --select-1 \
        | read -l result; and git checkout "$result"
end

function fcoc -d "Fuzzy-find and checkout a commit"
    git log --pretty=oneline --abbrev-commit --reverse \
        | fzf --tac +s -e \
        | awk '{print $1;}' \
        | read -l result; and git checkout "$result"
end

function snag -d "Pick desired files from a chosen branch"
    set -l branch (git for-each-ref --format='%(refname:short)' refs/heads | fzf --height 20% --layout=reverse --border)
    test -n "$branch"; or return

    set -l files (git diff --name-only $branch | fzf --height 20% --layout=reverse --border --multi)
    test -n "$files"; or return

    git checkout $branch $files
end

function fzum -d "View all unmerged commits across all local branches"
    set -l main (git_main_branch 2>/dev/null; or echo master)
    set -l preview "echo {} | head -1 | xargs -I BRANCH sh -c 'git log $main..BRANCH --no-merges --color --format=\"%C(auto)%h - %C(green)%ad%Creset - %s\" --date=format:\'%b %d %Y\''"

    git branch --no-merged $main --format "%(refname:short)" \
        | fzf --no-sort --reverse --tiebreak=index --no-multi --ansi --preview="$preview"
end
