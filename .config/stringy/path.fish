set -Ux GOPATH $HOME/code/go

fish_add_path /Users/ghutton/homebrew/opt/llvm/bin
fish_add_path $HOME/code/go/bin
fish_add_path $HOME/homebrew/bin

if test -f $HOME/etc/nvim-osx64
    fish_add_path $HOME/ext/nvim-osx64/bin
end

if test -f $HOME/scripts
    fish_add_path $HOME/scripts
end

if test -f $HOME/homebrew/opt/bin/utils
    fish_add_path $HOME/homebrew/opt/bin/utils/bin
end

set -Ux LIBRARY_PATH :/opt/homebrew/lib
