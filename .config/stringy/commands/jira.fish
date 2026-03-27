
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
