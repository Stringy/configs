
source $HOME/.config/stringy/utils.fish

alias vim="nvim"
alias config="/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME"
alias editstringy="nvim $HOME/.config/stringy"
alias hm="history --merge"

source $HOME/.config/stringy/binds.fish

source $HOME/.config/stringy/path.fish
source $HOME/.config/stringy/stackrox.fish
source $HOME/.config/stringy/collector.fish

for cfg in $HOME/.config/stringy/commands/*.fish
    source $cfg
end

for cfg in $HOME/.config/stringy/tools/*.fish
    source $cfg
end

source $HOME/.config/stringy/fish/plugins.fish
source $HOME/.config/stringy/vms.fish
source $HOME/.config/stringy/writing.fish

alias cdme="cd $HOME/code/stringy"
alias cdg="cd $HOME/code/go/src/github.com"

gpgconf --create-socketdir

set -gx GPG_TTY (tty)
