
function complete_in_dir
    set prevdir $PWD
    cd $argv[1]
    __fish_complete_directories
    cd $prevdir
end

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'

function git_repo_root --description "Get the main repo root (works from inside worktrees)"
    set -l common (git rev-parse --git-common-dir 2>/dev/null)
    or begin
        echo "Error: not in a git repository" >&2
        return 1
    end
    echo (string replace -r '/\.git$' '' -- (realpath $common))
end

function git_main_branch --description "Get the main branch name from origin/HEAD"
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
end

function git_dirty_count --description "Count uncommitted changes in a directory"
    count (git -C $argv[1] status --porcelain 2>/dev/null)
end

function tmux_title --description "Set the tmux window name"
    test -n "$TMUX"; or return
    if test (count $argv) -ge 2
        tmux rename-window "$argv[1]:$argv[2]"
    else
        tmux rename-window "$argv[1]"
    end
end
