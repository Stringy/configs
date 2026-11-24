function mermaid --description "Render a Mermaid diagram"
    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "Usage: mermaid <input.mmd> [output.svg]"
        return 2
    end

    set -l input $argv[1]
    if not test -f "$input"
        echo "Error: input file not found: $input" >&2
        return 1
    end

    set -l output $argv[2]
    if test -z "$output"
        set output (string replace -r '\.[^.]+$' '' -- "$input").svg
    end

    npx --yes @mermaid-js/mermaid-cli -i "$input" -o "$output"
end

complete -c mermaid -f -a '(__fish_complete_suffix .mmd)' -d "Mermaid diagram"
