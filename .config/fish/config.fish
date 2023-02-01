if status is-interactive
    # Commands to run in interactive sessions can go here
end

function complete_in_dir
    set saved_pwd $PWD
    builtin cd $argv[1] and complete -C "cd"
    builtin cd $saved_pwd
end

source $HOME/.config/stringy/common.fish
