
function vssh --description 'SSH into a vagrant VM'
    pushd "$HOME/vagrant/$argv[1]" or return
        vagrant ssh -- $argv[2..]
    popd
end

function vcd --description 'Go to a specific vagrant VM'
    cd "$HOME/vagrant/$argv[1]"
end

alias vup="vagrant up"

complete --command vssh -F --arguments "(complete_in_dir $HOME/vagrant)"
complete --command vcd -F --arguments "(complete_in_dir $HOME/vagrant)"
