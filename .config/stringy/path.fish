set -gx GOPATH $HOME/code/go

fish_add_path $HOME/code/go/bin
fish_add_path $HOME/.cargo/bin
fish_add_path /home/linuxbrew/.linuxbrew/bin
fish_add_path $HOME/.local/bin
fish_add_path /usr/local/go/bin
fish_add_path $HOME/bin
fish_add_path $HOME/bin/c3

if test (uname) = Darwin
    fish_add_path $HOME/homebrew/opt/llvm/bin
    fish_add_path $HOME/homebrew/bin
    fish_add_path /opt/homebrew/bin
    set -gx LIBRARY_PATH /opt/homebrew/lib
end

if test -d $HOME/etc/nvim-osx64
    fish_add_path $HOME/etc/nvim-osx64/bin
end

if test -d $HOME/scripts
    fish_add_path $HOME/scripts
end

set -a XDG_DATA_DIRS $HOME/.local/share/flatpak/export/share/applications
