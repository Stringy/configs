
function novel-new --description "Create a new novel project from template"
    if test (count $argv) -lt 2
        echo "Usage: novel-new <path> \"Project Name\""
        echo "Example: novel-new ~/notes/tower \"The Tower\""
        return 1
    end

    set -l project_path $argv[1]
    set -l project_name $argv[2]
    set -l template_dir $HOME/.config/stringy/templates/novel

    if test -d $project_path
        echo "Error: $project_path already exists"
        return 1
    end

    if not test -d $template_dir
        echo "Error: novel template not found at $template_dir"
        return 1
    end

    echo "Creating novel project: $project_name"
    echo "Location: $project_path"

    mkdir -p $project_path/chapters $project_path/notes

    for f in $template_dir/*.md
        sed "s/{{PROJECT_NAME}}/$project_name/g" $f > $project_path/(basename $f)
    end

    git -C $project_path init --quiet
    git -C $project_path add -A
    git -C $project_path commit --quiet -m "Initial novel project: $project_name"

    echo ""
    echo "Created:"
    echo "  $project_path/CLAUDE.md        — Claude editorial instructions"
    echo "  $project_path/bible.md         — world bible (fill this in)"
    echo "  $project_path/chapters/        — one file per chapter"
    echo "  $project_path/notes/           — characters, timeline, research"
    echo ""
    echo "Start writing: cd $project_path"
end

function novel-wordcount --description "Word count across all chapters"
    set -l dir (pwd)
    if test (count $argv) -gt 0
        set dir $argv[1]
    end

    if not test -d $dir/chapters
        echo "No chapters/ directory found."
        return 1
    end

    set -l total 0
    for f in $dir/chapters/*.md
        set -l count (wc -w < $f)
        set total (math $total + $count)
        printf "  %-40s %s words\n" (basename $f) $count
    end
    echo ""
    echo "  Total: $total words"
end
