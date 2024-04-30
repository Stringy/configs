
set -gx NOVEL_BASE_DIR $HOME/Dropbox/Writing/Misc/Markdown

function novel
    nvim $NOVEL_BASE_DIR
end

function free-write
    nvim $NOVEL_BASE_DIR"/Free Writing/"(date +"%Y-%m-%d").md
end

function word-count
    if test -d "$argv[1]"
        find $argv[1] -name '*.md' | xargs -d '\n' wc -w
    else
        wc -w $argv[1]
    end
end
