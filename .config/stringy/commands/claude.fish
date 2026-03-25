
set -gx CLAUDE_CODE_USE_VERTEX 1
set -gx CLOUD_ML_REGION us-east5
set -gx ANTHROPIC_VERTEX_PROJECT_ID itpc-gcp-hcm-pe-eng-claude

set -gx CLAUDE_CONTAINER_DIR ~/.config/stringy/containers/claude-code
set -gx CLAUDE_IMAGE_NAME claude-code

# --- Container helpers ---

function claude-build --description "Build the Claude Code container image"
    podman build -t $CLAUDE_IMAGE_NAME $CLAUDE_CONTAINER_DIR $argv
end

function claude-run --description "Run Claude Code in a container, mounting gcloud creds and current directory"
    podman run -it --rm \
        -v ~/.config/gcloud:/home/claude/.config/gcloud:ro \
        -v ~/.claude:/home/claude/.claude \
        -v (pwd):/work \
        -w /work \
        $CLAUDE_IMAGE_NAME $argv
end

# --- Internal helpers ---

function __claude_worktrees --description "List Claude worktree paths in the given repo root"
    set -l repo_root $argv[1]
    git -C $repo_root worktree list --porcelain \
        | string match -r 'worktree .*/\.claude/worktrees/.*' \
        | string replace 'worktree ' ''
end

function __claude_slugify --description "Convert a string to a short URL-safe slug (3-4 words)"
    set -l stopwords a an the and or but in on at to for of is with by from as be
    set -l words

    for word in (string split ' ' -- (string lower -- $argv[1]))
        set -l clean (string replace -ra '[^a-z0-9]' '' -- $word)
        test -z "$clean"; and continue
        contains -- $clean $stopwords; and continue
        set -a words $clean
    end

    if test (count $words) -gt 4
        set words $words[1..4]
    end

    string join '-' -- $words
end

function __claude_find_worktree --description "Find an existing worktree by ticket ID"
    set -l ticket_lower (string lower -- $argv[1])

    for line in (git worktree list --porcelain 2>/dev/null)
        if string match -q "worktree *" -- $line
            set -l wt_path (string replace 'worktree ' '' -- $line)
            if string match -qi "*$ticket_lower*" -- (basename $wt_path)
                echo $wt_path
                return 0
            end
        end
    end
    return 1
end

function __claude_worktree_completions --description "List worktree names for tab completion"
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    and for wt in (__claude_worktrees $root)
        basename $wt
    end
end

function __claude_jira_completions --description "Cached Jira ticket completions (refreshes every 10 minutes)"
    set -l cache ~/.cache/claude-jira-completions
    set -l ttl 600

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache))
        if test $age -lt $ttl
            cat $cache
            return
        end
    end

    set -l result (jira issue list -a(jira me) -sNew -s'In Progress' -sReview --plain --no-headers --columns key,summary 2>/dev/null)
    if test $status -eq 0
        mkdir -p (dirname $cache)
        printf '%s\n' $result > $cache
        printf '%s\n' $result
    else if test -f $cache
        cat $cache
    end
end

# --- Main functions ---

function claude-switch --description "Create or resume a Claude worktree session for a Jira ticket"
    argparse 'r/repo=' 'p/prompt=' -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "Usage: claude-switch [-r repo_path] [-p prompt] TICKET-ID"
        return 1
    end

    set -l ticket (string upper -- $argv[1])

    set -l repo_root
    if set -ql _flag_r
        set repo_root $_flag_r
    else
        set repo_root (git_repo_root)
        or return 1
    end

    pushd $repo_root

    set -l existing_wt (__claude_find_worktree $ticket)
    if test -n "$existing_wt"
        echo "Resuming session in existing worktree: $existing_wt"
        tmux_title (basename $repo_root) (basename $existing_wt)
        cd $existing_wt
        if set -ql _flag_p
            claude --continue "$_flag_p"
        else
            claude --continue
        end
        popd
        return
    end

    echo "Fetching $ticket from Jira..."
    set -l raw_json (jira issue view $ticket --raw 2>/dev/null)
    if test $status -ne 0
        echo "Error: could not fetch $ticket from Jira"
        popd
        return 1
    end

    set -l title (printf '%s' $raw_json | jq -r '.fields.summary')
    if test -z "$title" -o "$title" = "null"
        echo "Error: could not extract title for $ticket"
        popd
        return 1
    end

    echo "Ticket: $title"

    set -l slug (__claude_slugify "$title")
    set -l wt_name (string lower -- $ticket)-$slug
    set -l branch_prefix (string lower -- (string split ' ' -- (git config user.name))[1])
    set -l branch_name $branch_prefix/$ticket-$slug
    set -l wt_path .claude/worktrees/$wt_name

    echo "Creating worktree: $wt_path"
    echo "Branch: $branch_name"

    git worktree add -b $branch_name $wt_path
    if test $status -ne 0
        echo "Error: failed to create worktree"
        popd
        return 1
    end

    cd $wt_path
    tmux_title (basename $repo_root) $wt_name

    set -l initial_prompt "I'm working on $ticket: $title. The Jira ticket description and context has been loaded. Let's get started."
    if set -ql _flag_p
        set initial_prompt "$initial_prompt $_flag_p"
    end

    claude --name $ticket "$initial_prompt"
    popd
end

function claude-resume --description "Resume a Claude session in a worktree (interactive picker)"
    set -l repo_root (git_repo_root)
    or return 1

    set -l worktrees (__claude_worktrees $repo_root)
    if test (count $worktrees) -eq 0
        echo "No Claude worktrees found."
        return 0
    end

    set -l choices
    for wt in $worktrees
        set -a choices (basename $wt)
    end

    set -l pick
    if test (count $choices) -eq 1
        set pick $choices[1]
    else if command -q fzf
        set pick (printf '%s\n' $choices | fzf --prompt="Select worktree: ")
    else
        echo "Available worktrees:"
        for i in (seq (count $choices))
            echo "  $i) $choices[$i]"
        end
        read -P "Select [1-"(count $choices)"]: " -l idx
        set pick $choices[$idx]
    end

    if test -z "$pick"
        return 1
    end

    tmux_title (basename $repo_root) $pick
    cd $repo_root/.claude/worktrees/$pick
    claude --continue
end

function claude-list --description "List all Claude worktrees (quick overview)"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)
    set -l worktrees (__claude_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No Claude worktrees found."
        return 0
    end

    echo "Claude worktrees in "(basename $repo_root)":"
    echo

    for wt in $worktrees
        set -l name (basename $wt)
        set -l branch (git -C $wt rev-parse --abbrev-ref HEAD 2>/dev/null)
        set -l ahead (git -C $wt rev-list --count origin/$main..HEAD 2>/dev/null; or echo "?")
        set -l dirty (git_dirty_count $wt)
        set -l marker ""
        test $dirty -gt 0; and set marker " [modified]"

        printf "  %-40s %s (%s commits)%s\n" $name $branch $ahead "$marker"
    end
end

function claude-clean --description "Remove a Claude worktree"
    if test (count $argv) -ne 1
        echo "Usage: claude-clean <worktree-name-or-ticket>"
        return 1
    end

    set -l repo_root (git_repo_root)
    or return 1

    set -l target $argv[1]

    pushd $repo_root

    set -l wt_path
    if test -d ".claude/worktrees/$target"
        set wt_path .claude/worktrees/$target
    else
        set wt_path (__claude_find_worktree $target)
    end

    if test -z "$wt_path"
        echo "No worktree found matching '$target'"
        popd
        return 1
    end

    set -l branch (git -C $wt_path rev-parse --abbrev-ref HEAD 2>/dev/null)

    echo "Removing worktree: $wt_path"
    read -P "Also delete branch '$branch'? [y/N] " -l confirm

    git worktree remove $wt_path
    if test $status -ne 0
        echo "Worktree has modifications. Use: git worktree remove --force $wt_path"
        popd
        return 1
    end

    if string match -qi 'y' -- $confirm
        git branch -d $branch 2>/dev/null
        or git branch -D $branch
    end

    popd
end

function claude-status --description "Show git status across all Claude worktrees"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)
    set -l worktrees (__claude_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No Claude worktrees found."
        return 0
    end

    echo "Claude worktrees in "(basename $repo_root)":"
    echo

    for wt in $worktrees
        set -l name (basename $wt)
        set -l branch (git -C $wt rev-parse --abbrev-ref HEAD 2>/dev/null)
        set -l ahead (git -C $wt rev-list --count origin/$main..HEAD 2>/dev/null; or echo "?")
        set -l behind (git -C $wt rev-list --count HEAD..origin/$main 2>/dev/null; or echo "?")
        set -l dirty (git_dirty_count $wt)
        set -l last_commit (git -C $wt log -1 --format='%cr: %s' 2>/dev/null)

        set_color cyan
        printf "  %s\n" $name
        set_color normal
        printf "    branch:  %s\n" $branch
        printf "    status:  %s ahead, %s behind origin/%s" $ahead $behind $main
        if test $dirty -gt 0
            set_color yellow
            printf ", %s uncommitted" $dirty
            set_color normal
        end
        echo
        printf "    latest:  %s\n" "$last_commit"

        if command -q gh
            set -l pr_url (gh pr list --head $branch --json url --jq '.[0].url' 2>/dev/null)
            if test -n "$pr_url"
                printf "    PR:      %s\n" $pr_url
            end
        end

        echo
    end
end

function claude-sync --description "Rebase all Claude worktrees onto latest main"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)

    echo "Fetching latest from origin..."
    git -C $repo_root fetch origin $main --quiet

    set -l worktrees (__claude_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No Claude worktrees to sync."
        return 0
    end

    for wt in $worktrees
        set -l name (basename $wt)
        set -l behind (git -C $wt rev-list --count HEAD..origin/$main 2>/dev/null; or echo 0)

        if test "$behind" = "0"
            printf "  %-40s already up to date\n" $name
            continue
        end

        set -l dirty (git_dirty_count $wt)
        if test $dirty -gt 0
            set_color yellow
            printf "  %-40s skipped (%s uncommitted changes)\n" $name $dirty
            set_color normal
            continue
        end

        printf "  %-40s rebasing (%s commits behind)..." $name $behind
        if git -C $wt rebase origin/$main --quiet 2>/dev/null
            set_color green
            echo " done"
            set_color normal
        else
            set_color red
            echo " CONFLICT - run 'cd $wt && git rebase --abort' or resolve manually"
            set_color normal
            git -C $wt rebase --abort 2>/dev/null
        end
    end
end

function claude-dash --description "Dashboard of all Claude worktrees with Jira status"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)
    set -l worktrees (__claude_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No Claude worktrees found."
        return 0
    end

    echo
    set_color --bold
    printf "  %-14s %-40s %-14s %-12s %s\n" "TICKET" "WORKTREE" "JIRA STATUS" "GIT" "PR"
    set_color normal
    echo "  "(string repeat -n 100 '─')

    for wt in $worktrees
        set -l name (basename $wt)
        set -l branch (git -C $wt rev-parse --abbrev-ref HEAD 2>/dev/null)

        # Extract ticket ID from worktree name (e.g. rox-12345-some-slug -> ROX-12345)
        set -l ticket (string upper -- (string match -r '^[a-z]+-[0-9]+' -- $name))

        # Git status summary
        set -l ahead (git -C $wt rev-list --count origin/$main..HEAD 2>/dev/null; or echo "?")
        set -l dirty (git_dirty_count $wt)
        set -l git_info $ahead"c"
        test $dirty -gt 0; and set git_info "$git_info +$dirty"

        # Jira status
        set -l jira_status "?"
        if test -n "$ticket"; and command -q jira
            set jira_status (jira issue view $ticket --raw 2>/dev/null | jq -r '.fields.status.name' 2>/dev/null)
            test -z "$jira_status" -o "$jira_status" = "null"; and set jira_status "?"
        end

        # PR status
        set -l pr_info "-"
        if command -q gh
            set -l pr_state (gh pr list --head $branch --json state --jq '.[0].state' 2>/dev/null)
            test -n "$pr_state"; and set pr_info $pr_state
        end

        # Colour the Jira status inline
        set -l jira_colour normal
        switch $jira_status
            case "In Progress"
                set jira_colour yellow
            case "Review"
                set jira_colour cyan
            case "Closed" "Done"
                set jira_colour green
        end

        printf "  %-14s %-40s " "$ticket" $name
        set_color $jira_colour
        printf "%-14s" "$jira_status"
        set_color normal
        printf " %-12s %s\n" "$git_info" "$pr_info"
    end
    echo
end

function claude-bg --description "Run Claude in background on a worktree task"
    if test (count $argv) -lt 2
        echo "Usage: claude-bg <ticket-or-worktree> \"prompt\""
        return 1
    end

    set -l target $argv[1]
    set -l prompt $argv[2..-1]

    set -l repo_root (git_repo_root)
    or return 1

    pushd $repo_root

    set -l wt_path
    if test -d ".claude/worktrees/$target"
        set wt_path (realpath .claude/worktrees/$target)
    else
        set wt_path (__claude_find_worktree $target)
    end

    if test -z "$wt_path"
        echo "No worktree found matching '$target'. Create one first with claude-switch."
        popd
        return 1
    end

    set -l name (basename $wt_path)
    set -l logfile /tmp/claude-bg-$name-(date +%Y%m%d-%H%M%S).log

    echo "Starting background Claude session in $name"
    echo "Output: $logfile"

    cd $wt_path
    claude --print --continue "$prompt" > $logfile 2>&1 &
    set -l pid $last_pid

    echo "PID: $pid"
    echo
    echo "Monitor with: tail -f $logfile"
    echo "Or wait with: wait $pid && cat $logfile"

    popd
end

function claude-review --description "Check out a PR into a worktree and start a code review"
    if test (count $argv) -ne 1
        echo "Usage: claude-review <PR-number|ROX-ticket>"
        return 1
    end

    set -l input $argv[1]
    set -l repo_root (git_repo_root)
    or return 1

    pushd $repo_root

    # Resolve input to a PR number
    set -l pr_number
    if string match -qr '^\d+$' -- $input
        set pr_number $input
    else
        set -l ticket (string upper -- $input)
        echo "Searching for PRs matching $ticket..."
        set -l result (gh pr list --search "$ticket" --json number,headRefName,title --limit 5 2>/dev/null)
        set -l count (printf '%s' $result | jq 'length')

        if test "$count" = "0"
            echo "No open PRs found for $ticket"
            popd
            return 1
        else if test "$count" = "1"
            set pr_number (printf '%s' $result | jq -r '.[0].number')
        else
            echo "Multiple PRs found:"
            printf '%s' $result | jq -r '.[] | "  #\(.number) \(.title)"'
            read -P "PR number: " pr_number
        end
    end

    # Fetch PR details
    set -l pr_json (gh pr view $pr_number --json headRefName,title,number 2>/dev/null)
    if test $status -ne 0
        echo "Error: could not fetch PR #$pr_number"
        popd
        return 1
    end

    set -l pr_title (printf '%s' $pr_json | jq -r '.title')
    set -l pr_branch (printf '%s' $pr_json | jq -r '.headRefName')

    echo "PR #$pr_number: $pr_title"
    echo "Branch: $pr_branch"

    # Check for existing worktree
    set -l wt_name review-$pr_number
    set -l wt_path .claude/worktrees/$wt_name

    if test -d "$wt_path"
        echo "Resuming review in existing worktree: $wt_path"
        tmux_title (basename $repo_root) $wt_name
        cd $wt_path
        claude --continue
        popd
        return
    end

    # Fetch the PR branch and create worktree
    git fetch origin $pr_branch 2>/dev/null
    git worktree add $wt_path origin/$pr_branch 2>/dev/null
    if test $status -ne 0
        echo "Error: failed to create worktree"
        popd
        return 1
    end

    cd $wt_path
    tmux_title (basename $repo_root) $wt_name

    claude --name "review-$pr_number" "/review"
    popd
end

# Aliases
alias cs=claude-switch
alias cr=claude-resume
alias cl=claude-list
alias cx=claude-clean
alias ct=claude-status
alias cy=claude-sync
alias cb=claude-bg
alias co=claude-dash
alias cv=claude-review

# Tab completions
for cmd in claude-switch claude-review cs cv
    complete -c $cmd -f -a '(__claude_jira_completions)'
end
for cmd in claude-clean claude-resume claude-bg cx cr cb
    complete -c $cmd -f -a '(__claude_worktree_completions)'
end
