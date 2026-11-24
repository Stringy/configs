if command -q nono
    # Nono generates its command and option completions from the installed CLI.
    command nono completion fish | source

    if command -q jq
        function __nono_session_completions --description "List active Nono sessions for completion"
            command nono ps --json 2>/dev/null \
                | jq -r '.[] | select(.session_id != null) | [.session_id, (.name // .profile // "Nono session")] | @tsv'
        end

        for subcommand in attach detach stop inspect logs
            complete -c nono -n "__fish_seen_subcommand_from $subcommand" -f -a '(__nono_session_completions)'
        end
    end
end
