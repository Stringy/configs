
function complete_in_dir
    set prevdir $PWD
    cd $argv[1]
    __fish_complete_directories
    cd $prevdir
end

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
