
if command -q pyenv
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin

    # Defer pyenv init until first use — saves ~175ms on startup
    function pyenv --wraps pyenv
        functions -e pyenv
        pyenv init - | source
        pyenv $argv
    end
end
