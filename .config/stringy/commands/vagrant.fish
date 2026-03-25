
if command -q vagrant
    set -gx VAGRANT_VMS_ROOT $HOME/code/stringy/dev-tools/vagrant

    function vssh --description 'SSH into a vagrant VM'
        pushd "$VAGRANT_VMS_ROOT/$argv[1]"; or return
        vagrant ssh -- $argv[2..]
        popd
    end

    function vcd --description 'Go to a specific vagrant VM'
        cd "$VAGRANT_VMS_ROOT/$argv[1]"
    end

    function vup --description 'Bring up a vagrant VM'
        vagrant up $argv
    end

    function vssh-key-rm --description "Remove a vagrant VM's key from the SSH agent"
        vcd $argv[1]
        set -l ip (vagrant ssh -c "hostname -i | tr ' ' '\n' | grep 192 | tr -d '[:space:]'")
        ssh-keygen -R $ip
    end

    function vssh-add --description "Add a vagrant SSH key to the agent"
        vcd $argv[1]
        ssh-add .vagrant/machines/default/virtualbox/private_key
    end

    complete -x --command vcd --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
    complete -x --command vssh --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
    complete -x --command vssh-key-rm --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
    complete -x --command vssh-add --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
end
