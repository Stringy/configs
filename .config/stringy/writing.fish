
set -gx NOVEL_BASE_DIR $HOME/Dropbox/Writing/Misc/Markdown

function novel
    nvim $NOVEL_BASE_DIR
end

function free-write
    nvim $NOVEL_BASE_DIR"/Free Writing/"(date +"%Y-%m-%d").md
end

function word-count --description "Count words in a file or directory of markdown files"
    if test -d "$argv[1]"
        wc -w $argv[1]/**/*.md
    else
        wc -w $argv[1]
    end
end
