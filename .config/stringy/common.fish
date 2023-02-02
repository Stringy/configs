
alias vim="nvim"
alias config="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"

source $HOME/.config/stringy/path.fish
source $HOME/.config/stringy/stackrox.fish

for cfg in $HOME/.config/stringy/commands/*.fish
    source $cfg
end
