
if test -e $HOME/.config/secrets/jira
    set -gx JIRA_API_TOKEN (cat $HOME/.config/secrets/jira)
end

alias ji="jira issue list -a(jira me) -sNew -s'In Progress' -sReview"
alias jia="jira issue list -a(jira me) -r(jira me)"
alias jr="jira issue list -r(jira me) -sNew -s'In Progress' -sReview"

# Cache jira completions — regenerate when jira is updated
if command -q jira
    set -l cache ~/.cache/jira-completions.fish
    set -l jira_path (command -s jira)
    if not test -f $cache; or test $jira_path -nt $cache
        jira completion fish > $cache
    end
    source $cache
end

# --- General-purpose helpers ---

function __cached --description "Read from a TTL-based file cache, or run a command to populate it"
    set -l cache $argv[1]
    set -l ttl $argv[2]
    set -l cmd $argv[3..-1]

    if test -f $cache
        set -l age (math (date +%s) - (stat -c %Y $cache))
        if test $age -lt $ttl
            cat $cache
            return
        end
    end

    set -l result (eval $cmd 2>/dev/null)
    if test $status -eq 0
        mkdir -p (dirname $cache)
        printf '%s\n' $result > $cache
        printf '%s\n' $result
    else if test -f $cache
        cat $cache
    else
        return 1
    end
end

function __slugify --description "Convert a string to a short URL-safe slug (3-4 words)"
    set -l stopwords a an the and or but in on at to for of is with by from as be
    set -l words

    for word in (string split ' ' -- (string lower -- $argv[1]))
        set -l clean (string replace -ra '[^a-z0-9]' '' -- $word)
        test -z "$clean"; and continue
        contains -- $clean $stopwords; and continue
        set -a words $clean
    end

    test (count $words) -gt 4; and set words $words[1..4]
    string join '-' -- $words
end

function __jira_completions --description "Cached Jira ticket completions (refreshes every 10 minutes)"
    set -l result (__cached ~/.cache/jira-ticket-completions 600 \
        "jira issue list -a(jira me) -sNew -s'In Progress' -sReview --plain --no-headers --columns key,summary")
    test -n "$result"; and printf '%s\n' $result
end

function __jira_fetch --description "Fetch Jira ticket JSON with daily cache"
    __cached ~/.cache/jira-tickets/(string lower -- $argv[1]).json 86400 \
        "jira issue view $argv[1] --raw"
end
