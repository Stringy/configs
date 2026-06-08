
# --- Internal helpers ---

function __ralph_session_exists -d "Check if a paude session exists"
    paude list 2>/dev/null | string match -rq ".*$argv[1].*"
end

function __ralph_create -d "Create a paude session and run the Ralph loop"
    set -l session $argv[1]
    set -l label $argv[2]
    set -l max_iters $argv[3]
    set -l prompt $argv[4]
    set -l domain_args $argv[5..-1]

    echo "Creating paude session '$session'..."
    paude create $session --yolo --git $domain_args \
        -a "-p '$prompt'"

    if test $status -ne 0
        echo "Error: failed to create paude session"
        return 1
    end

    __ralph_loop $session $label $max_iters
end

function __ralph_loop -d "Run the Ralph connect/check loop"
    set -l session $argv[1]
    set -l label $argv[2]
    set -l max_iters $argv[3]

    for i in (seq $max_iters)
        echo ""
        set_color --bold
        echo "══ Ralph iteration $i / $max_iters — $label ══"
        set_color normal
        echo ""

        paude start $session 2>/dev/null
        paude connect $session

        # Check for completion signal
        set -l donefile (mktemp /tmp/ralph-done-check.XXXXXX)
        paude cp $session:.ralph-done $donefile 2>/dev/null
        if test $status -eq 0 -a -s $donefile
            echo ""
            set_color green
            echo "Agent signalled completion:"
            set_color normal
            cat $donefile
            rm -f $donefile
            break
        end
        rm -f $donefile

        if test $i -eq 1
            echo ""
            set_color yellow
            echo "First iteration complete. Review changes before continuing."
            set_color normal

            set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
            if test -n "$repo_root"
                git -C $repo_root fetch paude-$session 2>/dev/null
                and echo ""
                and git -C $repo_root diff HEAD...FETCH_HEAD -- 2>/dev/null | head -200
                set -l total_lines (git -C $repo_root diff HEAD...FETCH_HEAD -- 2>/dev/null | wc -l)
                if test $total_lines -gt 200
                    echo ""
                    echo "(showing 200 of $total_lines diff lines)"
                end
            else
                echo "(not in a git repo — skipping diff preview)"
            end

            echo ""
            read -P "Continue with remaining iterations? [y/N] " -l confirm
            if test "$confirm" != y -a "$confirm" != Y
                echo "Stopping after first iteration."
                break
            end
        end

        if test $i -lt $max_iters
            echo "Agent exited without completing. Reconnecting in 3s..."
            sleep 3
        end
    end

    echo ""
    set_color --bold
    echo "══ Ralph loop finished — $label ══"
    set_color normal
    echo ""
    echo "Next steps:"
    echo "  paude harvest $session -b <branch>         # pull changes to a local branch"
    echo "  paude connect $session                     # inspect the container"
    echo "  paude delete $session --confirm            # clean up"
end

function __ralph_domain_args -d "Build --allowed-domains args from flags or defaults"
    if test (count $argv) -gt 0
        for d in $argv
            echo --allowed-domains
            echo $d
        end
    else
        echo --allowed-domains
        echo default
    end
end

# --- Main functions ---

function ralph -d "Ralph loop a prompt in a paude container"
    argparse 'n/max-iters=' 'd/domains=+' 's/session=' 'h/help' -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: ralph [-n max-iters] [-d domains...] [-s session-name] \"prompt\""
        echo ""
        echo "Options:"
        echo "  -n, --max-iters    Maximum Ralph iterations (default: 5)"
        echo "  -d, --domains      Extra allowed domains (repeatable, default: 'default')"
        echo "  -s, --session      Session name (default: auto-generated from prompt)"
        echo "  -h, --help         Show this help"
        echo ""
        echo "Examples:"
        echo "  ralph \"Add retry logic to the ingestion pipeline\""
        echo "  ralph -n 10 -s my-refactor \"Refactor auth middleware\""
        return 0
    end

    set -l prompt_text (string join ' ' -- $argv)
    set -l max_iters 5
    set -q _flag_max_iters; and set max_iters $_flag_max_iters

    set -l session
    if set -q _flag_session
        set session $_flag_session
    else
        set session (string lower -- (__slugify "$prompt_text"))
        test -z "$session"; and set session ralph-(random)
    end

    if __ralph_session_exists $session
        echo "Session '$session' already exists."
        read -P "Reconnect and continue Ralph loop? [y/N] " -l confirm
        if test "$confirm" != y -a "$confirm" != Y
            return 0
        end
        __ralph_loop $session $session $max_iters
        return $status
    end

    set -l domain_args (__ralph_domain_args $_flag_domains)

    set -l agent_prompt "$prompt_text

Follow existing code patterns. Run tests to verify your changes. When you are fully done, write a short summary of what you changed to a file called .ralph-done"

    __ralph_create $session $session $max_iters "$agent_prompt" $domain_args
end

function ralph-jira -d "Ralph loop a Jira ticket in a paude container"
    argparse 'n/max-iters=' 'd/domains=+' 'h/help' -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: ralph-jira [-n max-iters] [-d domains...] TICKET-KEY"
        echo ""
        echo "Options:"
        echo "  -n, --max-iters  Maximum Ralph iterations (default: 5)"
        echo "  -d, --domains    Extra allowed domains (repeatable, default: 'default')"
        echo "  -h, --help       Show this help"
        echo ""
        echo "Examples:"
        echo "  ralph-jira ROX-12345"
        echo "  ralph-jira -n 10 ROX-12345"
        echo "  ralph-jira -d default -d .github.com ROX-12345"
        return 0
    end

    set -l ticket (string upper -- $argv[1])
    set -l max_iters 5
    set -q _flag_max_iters; and set max_iters $_flag_max_iters

    set -l session (string lower -- (string replace -a '/' '-' -- $ticket))

    if __ralph_session_exists $session
        echo "Session '$session' already exists."
        read -P "Reconnect and continue Ralph loop? [y/N] " -l confirm
        if test "$confirm" != y -a "$confirm" != Y
            return 0
        end
        __ralph_loop $session $ticket $max_iters
        return $status
    end

    # Fetch ticket (reuses __jira_fetch cache)
    echo "Fetching $ticket from Jira..."
    set -l raw_json (__jira_fetch $ticket)
    if test $status -ne 0
        echo "Error: could not fetch $ticket from Jira"
        return 1
    end

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
        return 1
    end

    echo "Ticket: $title"

    # Build TASK.md content
    set -l task_content "# $ticket: $title

## Ticket Details
- Type: $issue_type | Status: $jira_status | Priority: $jira_priority"

    test -n "$epic_key"
        and set task_content "$task_content
- Epic: $epic_key — $epic_title"

    test -n "$description"
        and set task_content "$task_content

## Description
$description"

    test -n "$linked_issues"
        and set task_content "$task_content

## Linked Issues
$linked_issues"

    test -n "$comments"
        and set task_content "$task_content

## Recent Comments
$comments"

    set -l taskfile (mktemp /tmp/ralph-task.XXXXXX.md)
    printf '%s\n' $task_content > $taskfile

    set -l domain_args (__ralph_domain_args $_flag_domains)

    set -l agent_prompt "You are working on Jira ticket $ticket. Read TASK.md for the full ticket description and context. Implement the work described. Follow existing code patterns. Run tests to verify your changes. When you are fully done, write a short summary of what you changed to a file called .ralph-done"

    echo "Creating paude session '$session'..."
    paude create $session --yolo --git $domain_args \
        -a "-p '$agent_prompt'"

    if test $status -ne 0
        echo "Error: failed to create paude session"
        rm -f $taskfile
        return 1
    end

    echo "Copying task file into container..."
    paude cp $taskfile $session:TASK.md
    rm -f $taskfile

    __ralph_loop $session $ticket $max_iters
end

# Aliases
alias rj=ralph-jira
alias rp=ralph

# Tab completions
complete -c ralph-jira -f -a '(__jira_completions)'
complete -c ralph-jira -s n -l max-iters -d "Maximum Ralph iterations" -x
complete -c ralph-jira -s d -l domains -d "Extra allowed domains" -x

complete -c ralph -s n -l max-iters -d "Maximum Ralph iterations" -x
complete -c ralph -s d -l domains -d "Extra allowed domains" -x
complete -c ralph -s s -l session -d "Session name" -x
