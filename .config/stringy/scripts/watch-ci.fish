#!/usr/bin/env fish
#
# Background CI watcher — tool-agnostic
# Usage: watch-ci.fish PR_NUMBER BRANCH INTERVAL PIDFILE LOGFILE [TRIAGE_CMD...]
#
# TRIAGE_CMD is an optional command to run on failure (e.g. "opencode run ..." or "claude --print ...").
# It receives the PR number and branch as env vars: WATCH_CI_PR and WATCH_CI_BRANCH.

set -l pr_number $argv[1]
set -l branch $argv[2]
set -l interval $argv[3]
set -l pidfile $argv[4]
set -l logfile $argv[5]
set -l triage_cmd $argv[6..-1]

echo %self > $pidfile
echo "Watching CI for PR #$pr_number ($branch)" > $logfile
echo "Started: "(date) >> $logfile
echo "Interval: $interval""s" >> $logfile

while true
    set -l checks (gh pr view $pr_number --json statusCheckRollup --jq '.statusCheckRollup' 2>/dev/null)
    set -l total (printf '%s' $checks | jq 'length')

    if test "$total" = "0" -o "$total" = ""
        echo (date +%H:%M:%S)" No checks found" >> $logfile
        sleep $interval
        continue
    end

    # Count pending: CheckRun uses status (COMPLETED), StatusContext uses state (PENDING)
    set -l pending (printf '%s' $checks | jq '
        [.[] | if .__typename == "CheckRun" then
            select(.status != "COMPLETED")
        else
            select(.state == "PENDING")
        end] | length' 2>/dev/null)

    if test "$pending" = "0"
        # All done — check for failures
        set -l failures (printf '%s' $checks | jq '
            [.[] | if .__typename == "CheckRun" then
                select(.conclusion == "FAILURE" or .conclusion == "failure")
            else
                select(.state == "FAILURE")
            end] | length' 2>/dev/null)

        set -l summary (printf '%s' $checks | jq -r '
            .[] | if .__typename == "CheckRun" then
                "\(.name): \(.conclusion // "skipped")"
            else
                "\(.context): \(.state)"
            end' 2>/dev/null)

        if test "$failures" -gt 0
            echo (date +%H:%M:%S)" CI FAILED ($failures failures)" >> $logfile
            printf '%s\n' $summary >> $logfile
            notify-send -u critical "CI Failed" "PR #$pr_number: $failures failure(s)"

            if test (count $triage_cmd) -gt 0
                set -l slug (string replace -a '/' '-' -- $branch)
                set -l triage_log /tmp/ci-triage-$slug-(date +%Y%m%d-%H%M%S).log
                echo "Starting triage: $triage_log" >> $logfile
                WATCH_CI_PR=$pr_number WATCH_CI_BRANCH=$branch \
                    $triage_cmd > $triage_log 2>&1 &
            end
        else
            echo (date +%H:%M:%S)" CI PASSED" >> $logfile
            printf '%s\n' $summary >> $logfile
            notify-send -u normal "CI Passed" "PR #$pr_number: all checks passed"
        end

        rm -f $pidfile
        break
    end

    echo (date +%H:%M:%S)" $pending of $total checks pending" >> $logfile
    sleep $interval
end
