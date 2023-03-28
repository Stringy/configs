
function ssh-add-if-not-exists --description "Add an SSH key if it does not exist in the SSH agent"
    if test -f $argv[1]
        if ssh-add -l | grep -q (ssh-keygen -lf "$argv[1]" | awk '{print $2}')
            return 0
        else
            ssh-add $argv[1]
        end
    end
end

ssh-add-if-not-exists $HOME/.ssh/google_compute_engine
