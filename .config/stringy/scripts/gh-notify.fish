#!/usr/bin/env fish
#
# Poll GitHub notifications and send desktop alerts for PR comments
# Usage: gh-notify.fish [interval_seconds]
#
# Tracks last-checked time to avoid duplicate notifications.

set -l interval (test (count $argv) -gt 0; and echo $argv[1]; or echo 60)
set -l state_file ~/.cache/gh-notify-last-check
set -l logfile ~/.cache/gh-notify.log
set -l pidfile /tmp/gh-notify.pid

echo %self > $pidfile

# Initialise last check time
if test -f $state_file
    set -l last_check (cat $state_file)
else
    set -l last_check (date -u +%Y-%m-%dT%H:%M:%SZ)
end

echo (date +%H:%M:%S)" Started, polling every $interval""s" >> $logfile

while true
    set -l since $last_check
    set -l now (date -u +%Y-%m-%dT%H:%M:%SZ)

    set -l notifications (gh api notifications \
        --method GET \
        -f since="$since" \
        -f participating=true \
        --jq '.[] | select(.reason == "comment" or .reason == "review_requested" or .reason == "mention") | "\(.reason)\t\(.subject.title)\t\(.repository.full_name)\t\(.subject.url)"' \
        2>/dev/null)

    set -l count 0
    for line in $notifications
        set -l parts (string split \t -- $line)
        set -l reason $parts[1]
        set -l title $parts[2]
        set -l repo $parts[3]
        set -l api_url $parts[4]

        # Convert API URL to browser URL
        # https://api.github.com/repos/owner/repo/pulls/123 -> https://github.com/owner/repo/pull/123
        set -l html_url (string replace 'https://api.github.com/repos/' 'https://github.com/' -- $api_url | string replace '/pulls/' '/pull/' | string replace '/issues/' '/issues/')

        set count (math $count + 1)
        echo (date +%H:%M:%S)" [$reason] $repo: $title" >> $logfile

        set -l heading
        switch $reason
            case comment
                set heading "PR Comment"
            case review_requested
                set heading "Review Requested"
            case mention
                set heading "Mentioned"
        end

        test -z "$heading"; and continue

        # Non-blocking: clicking the notification opens the PR in the browser.
        # timeout prevents notify-send -A from hanging forever if the daemon never responds.
        fish -c "
            set -l action (timeout 30 notify-send -u normal -A 'default=Open' '$heading' '$repo: $title')
            if test \"\$action\" = 'default'
                xdg-open '$html_url'
            end
        " &
    end

    if test $count -eq 0
        echo (date +%H:%M:%S)" Checked — no new notifications" >> $logfile
    end

    echo $now > $state_file
    set last_check $now

    sleep $interval
end
