
function ssh-add-if-not-exists --description "Add an SSH key if it does not exist in the SSH agent"
    test -f $argv[1]; or return
    ssh-add -l 2>/dev/null | grep -q (ssh-keygen -lf "$argv[1]" | awk '{print $2}')
    or ssh-add $argv[1]
end

# Only add keys if an agent is running
if test -n "$SSH_AUTH_SOCK" -o -n "$SSH_AGENT_PID"
    ssh-add-if-not-exists $HOME/.ssh/google_compute_engine
end
