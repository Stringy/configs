# --- Bitwarden CLI ---

function bw --description "Bitwarden CLI; prompts to unlock on first use in a locked shell"
    if test (count $argv) -eq 1
        switch $argv[1]
            case unlock
                bwunlock
                return
            case lock
                bwlock
                return
        end
    end
    if test -z "$BW_SESSION"; and status is-interactive
        bwunlock; or return 1
    end
    command bw $argv
end

function bwunlock --description "Unlock Bitwarden and set BW_SESSION for this shell"
    if not command -q bw
        echo "bitwarden CLI is not installed" >&2
        return 1
    end
    set -l key (command bw unlock --raw)
    if test $status -ne 0; or test -z "$key"
        echo "Unlock failed; BW_SESSION not changed" >&2
        return 1
    end
    set -gx BW_SESSION $key
    # stderr: bw output is routinely captured in command substitutions
    echo "Bitwarden unlocked for this shell" >&2
end

function bwlock --description "Lock Bitwarden and clear this shell's session key"
    command bw lock
    and set -e BW_SESSION
end

function bwsecret --description "Print a secret from Bitwarden; prompts to unlock if the vault is locked"
    # bwsecret [-o|--org] <item-name-or-id> [custom-field]   (default field: Key)
    # Searches your personal items by default; --org searches organisational ones.
    argparse 'o/org' -- $argv
    or return 1
    if test (count $argv) -lt 1; or test (count $argv) -gt 2
        echo "Usage: bwsecret [-o|--org] <item-name-or-id> [custom-field]" >&2
        return 1
    end
    set -l name $argv[1]
    set -l field Key
    test (count $argv) -eq 2; and set field $argv[2]
    set -l scope mine
    set -ql _flag_org; and set scope org

    # __bw_item resolves through the `bw` wrapper, which prompts to unlock when
    # the vault is locked. Fish runs command substitutions in-process, so the
    # session key persists to the shell.
    set -l item (__bw_item "$name" $scope)
    set -l st $status

    # Ambiguity cannot be fixed by a sync; __bw_item has already explained
    if test $st -eq 2
        return 1
    end

    set -l value ''
    test -n "$item"; and set value (printf '%s\n' $item | __bw_field "$field")

    if test -z "$value"; and test -n "$BW_SESSION"
        # The item or its field may be missing from the local cache, which bw
        # refreshes only on explicit sync; retry once after syncing
        command bw sync --nointeraction >/dev/null 2>&1
        set item (__bw_item "$name" $scope)
        test -n "$item"; and set value (printf '%s\n' $item | __bw_field "$field")
    end

    if test -z "$value"
        __bw_report "$name" $scope "$field" "$item"
        return 1
    end

    printf '%s\n' $value
end

function __bw_item --description "Resolve a search term to a single Bitwarden item's JSON"
    # __bw_item <name-or-id> <mine|org>; exit 0 found, 1 not found, 2 ambiguous
    set -l term $argv[1]
    # GUIDs are globally unique, so they resolve directly without a scope filter
    if string match -qr '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$' -- $term
        bw get item "$term" --nointeraction 2>/dev/null | jq -c .
        return
    end
    set -l org false
    test "$argv[2]" = org; and set org true
    set -l json (bw list items --search "$term" --nointeraction 2>/dev/null | string collect)
    if test -z "$json"
        return 1
    end
    set -l n (printf '%s\n' $json | jq --argjson org $org '[.[] | select((.organizationId != null) == $org)] | length')
    if test -z "$n"
        return 1
    end
    switch $n
        case 1
            printf '%s\n' $json | jq -c --argjson org $org '.[] | select((.organizationId != null) == $org)'
        case 0
            return 1
        case '*'
            set -l where personal
            test $org = true; and set where organisational
            echo "More than one Bitwarden item matches '$term' among $where items:" >&2
            printf '%s\n' $json | jq -r --argjson org $org '.[] | select((.organizationId != null) == $org) | "  \(.name) (\(.id))"' >&2
            echo "Use the item's id instead of its name" >&2
            return 2
    end
end

function __bw_field --description "Extract a custom field value from Bitwarden item JSON on stdin"
    jq -r --arg f "$argv[1]" '.fields[]? | select(.name == $f) | .value // empty'
end

function __bw_report --description "Print the reason a bwsecret lookup failed"
    # __bw_report <name> <scope> <field> <item-json-or-nothing>
    if test -z "$argv[4]"
        set -l where personal
        test "$argv[2]" = org; and set where organisational
        echo "Could not fetch Bitwarden item '$argv[1]' among $where items (not found, or the vault is locked — try 'bw unlock')" >&2
        return
    end
    set -l names (printf '%s\n' $argv[4] | jq -r '.fields[]? | .name' | string join ", ")
    test -n "$names"; or set names none
    echo "Bitwarden item '$argv[1]' has no custom field '$argv[3]' (available: $names)" >&2
end
