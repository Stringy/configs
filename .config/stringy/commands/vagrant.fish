set -Ux VAGRANT_VMS_ROOT $HOME/code/stringy/dev-tools/vagrant

function vssh --description 'SSH into a vagrant VM' --wraps "cd $VAGRANT_VMS_ROOT"
    pushd "$VAGRANT_VMS_ROOT/$argv[1]" or return
        vagrant ssh -- $argv[2..]
    popd
end

function vcd --description 'Go to a specific vagrant VM' --wraps "cd $VAGRANT_VMS_ROOT"
    cd "$VAGRANT_VMS_ROOT/$argv[1]"
end

function vup --wraps='vagrant up' --description 'Brings up a vagrant VM'
  vagrant up $argv;
end

complete -x --command vcd --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
complete -x --command vssh --arguments "(complete_in_dir $VAGRANT_VMS_ROOT)"
