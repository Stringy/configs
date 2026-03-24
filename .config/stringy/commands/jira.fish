
if test -e $HOME/.config/secrets/jira
    set -gx JIRA_API_TOKEN (cat $HOME/.config/secrets/jira)
end

alias ji="jira issue list -a(jira me) -sNew -s'In Progress' -sReview"
alias jia="jira issue list -a(jira me) -r(jira me)"
alias jr="jira issue list -r(jira me) -sNew -s'In Progress' -sReview"

if command -q jira
    jira completion fish | source
end
