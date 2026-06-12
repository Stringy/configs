
# --- OpenCode environment ---

if at_work
    set -gx GOOGLE_CLOUD_PROJECT $ANTHROPIC_VERTEX_PROJECT_ID
    set -gx VERTEX_LOCATION $CLOUD_ML_REGION
    set -gx GOOGLE_APPLICATION_CREDENTIALS $HOME/.config/gcloud/application_default_credentials.json
    set -gx OPENCODE_CONFIG $HOME/.config/opencode/work.json
else
    set -gx OPENCODE_CONFIG $HOME/.config/opencode/personal.json
end

alias ocode=opencode

# --- Internal helpers ---

function __opencode_worktrees --description "List OpenCode worktree paths in the given repo root"
    git -C $argv[1] worktree list --porcelain \
        | string match -r 'worktree .*/\.opencode/worktrees/.*' \
        | string replace 'worktree ' ''
end

function __opencode_wt_branch --description "Get branch name for a worktree path"
    git -C $argv[1] rev-parse --abbrev-ref HEAD 2>/dev/null
end

function __opencode_wt_ticket --description "Extract ticket ID (uppercased) from a worktree name"
    string upper -- (string match -r '^[a-z]+-[0-9]+' -- (basename $argv[1]))
end

function __opencode_find_worktree --description "Find an existing opencode worktree by substring match"
    set -l needle (string lower -- $argv[1])
    for line in (git worktree list --porcelain 2>/dev/null)
        if string match -q "worktree *" -- $line
            set -l wt_path (string replace 'worktree ' '' -- $line)
            # Only match worktrees under .opencode/worktrees/
            string match -q "*/.opencode/worktrees/*" -- $wt_path; or continue
            if string match -qi "*$needle*" -- (basename $wt_path)
                echo $wt_path
                return 0
            end
        end
    end
    return 1
end

function __opencode_stale_worktrees --description "List worktree paths with merged PRs"
    set -l repo_root $argv[1]
    for wt in (__opencode_worktrees $repo_root)
        set -l branch (__opencode_wt_branch $wt)
        set -l merged (gh pr list --head $branch --state merged --json number --jq '.[0].number' 2>/dev/null)
        test -n "$merged"; and echo $wt
    end
end

# --- Completions helpers ---

function __opencode_worktree_completions --description "List worktree names for tab completion"
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    and for wt in (__opencode_worktrees $root)
        basename $wt
    end
end

# Jira helpers live in jira.fish (__jira_completions, __jira_fetch, __slugify, __cached)

# --- Main functions ---

function opencode-switch --description "Create or resume an OpenCode worktree session for a Jira ticket"
    argparse 'r/repo=' 'p/prompt=' -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "Usage: opencode-switch [-r repo_path] [-p prompt] TICKET-ID"
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

    # Resume if worktree already exists
    set -l existing_wt (__opencode_find_worktree $ticket)
    if test -n "$existing_wt"
        tmux_title (basename $repo_root) (basename $existing_wt)

        echo "Resuming session in: "(basename $existing_wt)
        if set -ql _flag_p
            opencode --continue --prompt "$_flag_p" $existing_wt
        else
            opencode --continue $existing_wt
        end
        popd
        return
    end

    # Fetch ticket from Jira
    echo "Fetching $ticket from Jira..."
    set -l raw_json (__jira_fetch $ticket)
    if test $status -ne 0
        echo "Error: could not fetch $ticket from Jira"
        popd
        return 1
    end

    # Extract all fields in one jq call
    set -l jira_fields (printf '%s' $raw_json | jq -r '[
        .fields.summary // "",
        .fields.issuetype.name // "Unknown",
        .fields.status.name // "Unknown",
        .fields.priority.name // "Unknown",
        .fields.parent.key // "",
        .fields.parent.fields.summary // "",
        ([.fields.description | .. | .text? // empty] | join(" ")),
        ([.fields.issuelinks[]? | if .outwardIssue then "\(.type.outward) \(.outwardIssue.key): \(.outwardIssue.fields.summary) [\(.outwardIssue.fields.status.name)]" elif .inwardIssue then "\(.type.inward) \(.inwardIssue.key): \(.inwardIssue.fields.summary) [\(.inwardIssue.fields.status.name)]" else empty end] | join("\n")),
        ([.fields.comment.comments | .[-5:][]? | "\(.author.displayName): \([.body | .. | .text? // empty] | join(" "))"] | join("\n---\n"))
    ] | join("\t")' 2>/dev/null)

    set -l fields (string split \t -- $jira_fields)
    set -l title $fields[1]
    set -l issue_type $fields[2]
    set -l jira_status $fields[3]
    set -l jira_priority $fields[4]
    set -l epic_key $fields[5]
    set -l epic_title $fields[6]
    set -l description $fields[7]
    set -l linked_issues $fields[8]
    set -l comments $fields[9]

    if test -z "$title"
        echo "Error: could not extract title for $ticket"
        popd
        return 1
    end

    echo "Ticket: $title"

    set -l slug (__slugify "$title")
    set -l wt_name (string lower -- $ticket)-$slug
    set -l wt_name (string sub -l 64 -- $wt_name)

    tmux_title (basename $repo_root) $wt_name

    # Create worktree
    set -l wt_path .opencode/worktrees/$wt_name
    set -l main (git_main_branch)
    git fetch origin $main --quiet 2>/dev/null
    git worktree add -b $wt_name $wt_path origin/$main
    or begin
        echo "Error: could not create worktree"
        popd
        return 1
    end

    # Build enriched prompt
    set -l initial_prompt "I'm working on $ticket: $title

## Ticket Details
- Type: $issue_type | Status: $jira_status | Priority: $jira_priority"

    test -n "$epic_key"; and set initial_prompt "$initial_prompt
- Epic: $epic_key — $epic_title"

    test -n "$description"; and set initial_prompt "$initial_prompt

## Description
$description"

    test -n "$linked_issues"; and set initial_prompt "$initial_prompt

## Linked Issues
$linked_issues"

    test -n "$comments"; and set initial_prompt "$initial_prompt

## Recent Comments
$comments"

    set initial_prompt "$initial_prompt

Let's get started."
    set -ql _flag_p; and set initial_prompt "$initial_prompt $_flag_p"

    opencode --prompt "$initial_prompt" --title "$ticket" $wt_path
    popd
end

function opencode-resume --description "Resume an OpenCode session in a worktree"
    if test (count $argv) -eq 0
        # No argument: continue last session in current repo
        set -l repo_root (git_repo_root 2>/dev/null)
        if test -n "$repo_root"
            opencode --continue $repo_root
        else
            opencode --continue
        end
        return
    end

    set -l repo_root (git_repo_root)
    or return 1

    set -l wt_path (__opencode_find_worktree $argv[1])
    if test -z "$wt_path"
        echo "No worktree matching '$argv[1]'."
        return 1
    end

    tmux_title (basename $repo_root) (basename $wt_path)

    echo "Resuming session in: "(basename $wt_path)
    opencode --continue $wt_path
end

function opencode-list --description "List OpenCode sessions"
    opencode session list
end

function opencode-clean --description "Remove OpenCode worktrees"
    argparse 'f/force' 's/stale' -- $argv
    or return 1

    set -l repo_root (git_repo_root)
    or return 1

    set -l force_flag
    set -ql _flag_f; and set force_flag --force

    pushd $repo_root

    # Batch remove stale worktrees
    if set -ql _flag_s
        set -l stale (__opencode_stale_worktrees $repo_root)

        if test (count $stale) -eq 0
            echo "No stale worktrees."
            popd
            return 0
        end

        echo "Stale worktrees (merged PRs):"
        for wt in $stale
            echo "  "(basename $wt)
        end
        echo
        read -P "Remove all "(count $stale)" and their branches? [y/N] " -l confirm
        if not string match -qi 'y' -- $confirm
            popd
            return 0
        end

        for wt in $stale
            set -l branch (__opencode_wt_branch $wt)
            echo "Removing: "(basename $wt)
            git worktree remove $force_flag $wt 2>/dev/null
            and git branch -D $branch 2>/dev/null
            or echo "  Failed. Try: ocx -f -s"
        end

        popd
        return
    end

    # Single worktree removal
    if test (count $argv) -ne 1
        echo "Usage: opencode-clean [-f] [-s] <worktree-name-or-ticket>"
        echo "       opencode-clean -s    Remove all worktrees with merged PRs"
        popd
        return 1
    end

    set -l wt_path (__opencode_find_worktree $argv[1])
    if test -z "$wt_path"
        echo "No worktree found matching '$argv[1]'"
        popd
        return 1
    end

    set -l branch (__opencode_wt_branch $wt_path)
    echo "Removing worktree: "(basename $wt_path)
    read -P "Also delete branch '$branch'? [y/N] " -l confirm_branch

    git worktree remove $force_flag $wt_path
    if test $status -ne 0
        echo "Failed. Try: ocx -f $argv[1]"
        popd
        return 1
    end

    if string match -qi 'y' -- $confirm_branch
        git branch -d $branch 2>/dev/null
        or git branch -D $branch
    end

    popd
end

function opencode-stale --description "List worktrees with merged PRs ready for cleanup"
    set -l repo_root (git_repo_root)
    or return 1

    set -l stale (__opencode_stale_worktrees $repo_root)

    if test (count $stale) -eq 0
        echo "No stale worktrees."
        return 0
    end

    for wt in $stale
        set -l name (basename $wt)
        set -l branch (__opencode_wt_branch $wt)
        set -l pr_info (gh pr list --head $branch --state merged --json number,title --jq '.[0] | "#\(.number) \(.title)"' 2>/dev/null)
        set -l dirty (git_dirty_count $wt)
        printf "  %-40s %s" $name "$pr_info"
        test $dirty -gt 0; and printf " [%s uncommitted]" $dirty
        echo
    end
    echo ""
    echo "Clean up with: ocx -s"
end

function opencode-sync --description "Rebase all OpenCode worktrees onto latest main"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)

    echo "Fetching latest from origin..."
    git -C $repo_root fetch origin $main --quiet

    set -l worktrees (__opencode_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No OpenCode worktrees to sync."
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

function opencode-dash --description "Dashboard of all OpenCode worktrees with Jira status"
    set -l repo_root (git_repo_root)
    or return 1

    set -l main (git_main_branch)
    set -l worktrees (__opencode_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No OpenCode worktrees found."
        return 0
    end

    echo
    set_color --bold
    printf "  %-14s %-40s %-14s %-12s %s\n" "TICKET" "WORKTREE" "JIRA STATUS" "GIT" "PR"
    set_color normal
    echo "  "(string repeat -n 100 '─')

    for wt in $worktrees
        set -l name (basename $wt)
        set -l branch (__opencode_wt_branch $wt)
        set -l ticket (__opencode_wt_ticket $wt)

        set -l ahead (git -C $wt rev-list --count origin/$main..HEAD 2>/dev/null; or echo "?")
        set -l dirty (git_dirty_count $wt)
        set -l git_info $ahead"c"
        test $dirty -gt 0; and set git_info "$git_info +$dirty"

        set -l jira_status "?"
        if test -n "$ticket"; and command -q jira
            set jira_status (__jira_fetch $ticket | jq -r '.fields.status.name' 2>/dev/null)
            test -z "$jira_status" -o "$jira_status" = "null"; and set jira_status "?"
        end

        set -l pr_info "-"
        if command -q gh
            set -l pr_state (gh pr list --head $branch --json state --jq '.[0].state' 2>/dev/null)
            test -n "$pr_state"; and set pr_info $pr_state
        end

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

function opencode-bg --description "Send a prompt to OpenCode in a worktree (non-interactive)"
    if test (count $argv) -lt 2
        echo "Usage: opencode-bg <ticket-or-worktree> \"prompt\""
        return 1
    end

    set -l repo_root (git_repo_root)
    or return 1

    pushd $repo_root

    set -l wt_path (__opencode_find_worktree $argv[1])
    if test -z "$wt_path"
        echo "No worktree found matching '$argv[1]'. Create one first with opencode-switch."
        popd
        return 1
    end

    set -l name (basename $wt_path)
    echo "Running OpenCode in $name"

    opencode run --continue --dir $wt_path $argv[2..-1]

    popd
end

function opencode-review --description "Check out a PR and start a code review"
    if test (count $argv) -ne 1
        echo "Usage: opencode-review <PR-number|ROX-ticket>"
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

    set -l wt_name review-$pr_number
    set -l wt_path .opencode/worktrees/$wt_name

    if test -d "$wt_path"
        echo "Resuming review in existing worktree: $wt_path"
        tmux_title (basename $repo_root) $wt_name
        opencode --continue $wt_path
        popd
        return
    end

    git fetch origin $pr_branch 2>/dev/null
    git worktree add $wt_path origin/$pr_branch 2>/dev/null
    or begin
        echo "Error: could not create worktree for PR branch"
        popd
        return 1
    end

    tmux_title (basename $repo_root) $wt_name

    opencode --prompt "/review" --title "review-$pr_number" $wt_path
    popd
end

function opencode-summary --description "Summarise work across all OpenCode worktrees for standup"
    argparse 's/since=' 'c/claude' -- $argv
    or return 1

    set -l repo_root (git_repo_root)
    or return 1

    set -l since "yesterday"
    set -ql _flag_s; and set since $_flag_s

    set -l main (git_main_branch)
    set -l worktrees (__opencode_worktrees $repo_root)

    if test (count $worktrees) -eq 0
        echo "No OpenCode worktrees found."
        return 0
    end

    set -l lines
    set -a lines "# Work Summary — "(date +%Y-%m-%d)" (since $since)"
    set -a lines "Repository: "(basename $repo_root)
    set -a lines ""

    for wt in $worktrees
        set -l name (basename $wt)
        set -l branch (__opencode_wt_branch $wt)
        set -l ticket (__opencode_wt_ticket $wt)

        set -l commits (git -C $wt log --since="$since" --oneline 2>/dev/null)
        set -l commit_count (count $commits)
        set -l dirty (git_dirty_count $wt)
        set -l ahead (git -C $wt rev-list --count origin/$main..HEAD 2>/dev/null; or echo "?")

        set -l jira_status ""
        if test -n "$ticket"; and command -q jira
            set jira_status (__jira_fetch $ticket | jq -r '.fields.status.name // empty' 2>/dev/null)
        end

        set -l pr_info ""
        if command -q gh
            set pr_info (gh pr list --head $branch --json url,state --jq '.[0] | "\(.state) \(.url)"' 2>/dev/null)
        end

        set -a lines "## $ticket — $name"
        set -a lines "- Branch: $branch ($ahead commits ahead of $main)"
        test -n "$jira_status"; and set -a lines "- Jira: $jira_status"

        set -l activity "$commit_count commit(s) since $since"
        test $dirty -gt 0; and set activity "$activity, $dirty uncommitted changes"
        set -a lines "- Activity: $activity"

        if test $commit_count -gt 0
            set -a lines "- Recent commits:"
            for c in $commits
                set -a lines "  - $c"
            end
        end

        test -n "$pr_info"; and set -a lines "- PR: $pr_info"
        set -a lines ""
    end

    if set -ql _flag_c
        printf '%s\n' $lines | opencode run "Summarise this worktree activity as a concise standup update. Use plain English, group by ticket, mention blockers or things needing review. Keep it to 3-5 bullet points."
    else
        printf '%s\n' $lines
    end
end

function opencode-branch --description "Create or resume an OpenCode worktree session for an existing branch"
    argparse 'p/prompt=' -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "Usage: opencode-branch [-p prompt] <branch-name>"
        return 1
    end

    set -l branch $argv[1]
    set -l repo_root (git_repo_root)
    or return 1

    pushd $repo_root

    set -l wt_name (string replace -a '/' '-' -- $branch)

    set -l existing_wt (__opencode_find_worktree $wt_name)
    if test -n "$existing_wt"
        tmux_title (basename $repo_root) (basename $existing_wt)

        echo "Resuming session in: "(basename $existing_wt)
        if set -ql _flag_p
            opencode --continue --prompt "$_flag_p" $existing_wt
        else
            opencode --continue $existing_wt
        end
        popd
        return
    end

    set -l wt_path .opencode/worktrees/$wt_name

    tmux_title (basename $repo_root) $wt_name

    if git rev-parse --verify $branch >/dev/null 2>&1
        git worktree add $wt_path $branch
    else
        echo "Branch '$branch' not found — creating from "(git_main_branch)
        git worktree add -b $branch $wt_path origin/(git_main_branch)
    end
    or begin
        echo "Error: could not create worktree for branch '$branch'"
        popd
        return 1
    end

    if set -ql _flag_p
        opencode --prompt "$_flag_p" $wt_path
    else
        opencode $wt_path
    end

    popd
end

function opencode-watch --description "Watch CI for a PR and notify on completion"
    argparse 't/triage' 'i/interval=' -- $argv
    or return 1

    if test (count $argv) -ne 1
        echo "Usage: opencode-watch [-t] [-i seconds] <PR#|ticket|worktree>"
        return 1
    end

    set -l input $argv[1]
    set -l repo_root (git_repo_root)
    or return 1

    set -l interval 300
    set -ql _flag_i; and set interval $_flag_i

    pushd $repo_root

    # Resolve to PR number and branch
    set -l pr_number
    set -l branch
    set -l wt_path

    if string match -qr '^\d+$' -- $input
        set pr_number $input
    else
        set wt_path (__opencode_find_worktree $input)
        if test -n "$wt_path"
            set branch (__opencode_wt_branch $wt_path)
            set pr_number (gh pr list --head $branch --json number --jq '.[0].number' 2>/dev/null)
        end
    end

    if test -z "$pr_number"
        echo "Error: could not find a PR for '$input'"
        popd
        return 1
    end

    test -z "$branch"; and set branch (gh pr view $pr_number --json headRefName --jq '.headRefName' 2>/dev/null)

    set -l slug (string replace -a '/' '-' -- $branch)
    set -l logfile /tmp/ci-watch-$slug.log
    set -l pidfile /tmp/ci-watch-$slug.pid

    if test -f $pidfile; and kill -0 (cat $pidfile) 2>/dev/null
        echo "Already watching PR #$pr_number (PID "(cat $pidfile)")"
        popd
        return 1
    end

    echo "Watching CI for PR #$pr_number ($branch) every "$interval"s"

    set -l triage_cmd
    if set -ql _flag_t; and test -n "$wt_path"
        set triage_cmd opencode run --continue --dir $wt_path \
            "triage: CI has failed on PR #$pr_number. Check gh pr view $pr_number --json statusCheckRollup for details. Identify the root cause and suggest a fix."
    end

    $STRINGY_SCRIPTS_ROOT/watch-ci.fish $pr_number $branch $interval $pidfile $logfile $triage_cmd &

    echo "PID: $last_pid"
    echo "Log: $logfile"
    echo "Monitor with: tail -f $logfile"

    popd
end

function opencode-watches --description "List active CI watchers"
    set -l found 0
    for pidfile in /tmp/ci-watch-*.pid
        test -f $pidfile; or continue
        set -l pid (cat $pidfile)
        if kill -0 $pid 2>/dev/null
            set found (math $found + 1)
            set -l slug (string replace -r '.*/ci-watch-(.*)\.pid' '$1' -- $pidfile)
            set -l logfile /tmp/ci-watch-$slug.log
            set -l branch (head -1 $logfile 2>/dev/null | string replace 'Watching CI for ' '')
            set -l started (sed -n '2p' $logfile 2>/dev/null | string replace 'Started: ' '')
            set -l last_status (tail -1 $logfile 2>/dev/null)

            printf "  PID %-8s %-40s (since %s)\n" $pid $branch "$started"
            printf "               %s\n" "$last_status"
        else
            rm -f $pidfile
        end
    end
    test $found -eq 0; and echo "No active watchers."
end

function opencode-personal --description "Start OpenCode using personal Anthropic account (bypasses Vertex)"
    GOOGLE_CLOUD_PROJECT= VERTEX_LOCATION= GOOGLE_APPLICATION_CREDENTIALS= OPENCODE_CONFIG= \
        opencode $argv
end

# --- Aliases ---
alias ocs=opencode-switch
alias ocr=opencode-resume
alias ocl=opencode-list
alias ocx=opencode-clean
alias ocy=opencode-sync
alias ocbg=opencode-bg
alias ocd=opencode-dash
alias ocv=opencode-review
alias ocm=opencode-summary
alias ocb=opencode-branch
alias ocw=opencode-watch
alias ocws=opencode-watches

# --- Tab completions ---
for cmd in opencode-switch opencode-review ocs ocv
    complete -c $cmd -f -a '(__jira_completions)'
end
for cmd in opencode-clean opencode-resume opencode-bg opencode-watch ocx ocr ocbg ocw
    complete -c $cmd -f -a '(__opencode_worktree_completions)'
end
for cmd in opencode-branch ocb
    complete -c $cmd -f -a '(git branch --format "%(refname:short)" 2>/dev/null)'
end
