
function ssh-add-if-not-exists --description "Add an SSH key if it does not exist in the SSH agent"
    if test -f $argv[1]
        if ssh-add -l | grep -q (ssh-keygen -lf "$argv[1]" | awk '{print $2}')
            echo "[*] $argv[1] has already been added to the ssh agent"
        else
            ssh-add $argv[1]
        end
    end
end

ssh-add-if-not-exists $HOME/.ssh/id_rsa
ssh-add-if-not-exists $HOME/.ssh/id_ed25519
ssh-add-if-not-exists $HOME/.ssh/google_compute_engine
