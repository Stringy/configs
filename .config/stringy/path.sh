#!/bin/bash

export PATH="/Users/ghutton/homebrew/opt/llvm/bin:$PATH"

export GOPATH="$HOME/code/go"

export PATH="$HOME/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/code/go/bin"

export PYTHON_BIN_PATH="$(python3 -m site --user-base)/bin"
export PATH="$PATH:$PYTHON_BIN_PATH"

if [ -d "$HOME/ext/nvim-osx64" ]; then
    export PATH="$PATH:$HOME/ext/nvim-osx64/bin"
fi

if [ -d "$HOME/scripts" ]; then
    export PATH="$PATH:$HOME/scripts"
fi

if [ -d "$HOME/homebrew/opt/binutils" ]; then
    export PATH="$PATH:$HOME/homebrew/opt/binutils/bin"
fi

export LIBRARY_PATH=:/opt/homebrew/lib
