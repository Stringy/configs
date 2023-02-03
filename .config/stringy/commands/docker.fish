
function docker-bash --description "run bash in a given image"
    argparse h/help -- $argv

    if set -ql _flag_help
        echo "docker-bash [-h|--help] <image>"
        return 0
    end

    docker run -it --rm --entrypoint bash $argv[1]
end
