
function gemini-ai-key
    set -l key (gcloud services api-keys get-key-string --project acs-senseco-ai-playground bdc2ab7d-5484-4e9a-8e9c-1989036097c3 | string split ' ' -f2)
    set -gx GEMINI_API_KEY $key
end

set -gx CLAUDE_CODE_USE_VERTEX 1
set -gx CLOUD_ML_REGION us-east5
set -gx ANTHROPIC_VERTEX_PROJECT_ID itpc-gcp-hcm-pe-eng-claude

set -gx CLAUDE_CONTAINER_DIR ~/.config/stringy/containers/claude-code
set -gx CLAUDE_IMAGE_NAME claude-code

function claude-build --description "Build the Claude Code container image"
    podman build -t $CLAUDE_IMAGE_NAME $CLAUDE_CONTAINER_DIR $argv
end

function claude-run --description "Run Claude Code in a container, mounting gcloud creds and current directory"
    podman run -it --rm \
        -v ~/.config/gcloud:/home/claude/.config/gcloud:ro \
        -v ~/.claude:/home/claude/.claude \
        -v (pwd):/work \
        -w /work \
        $CLAUDE_IMAGE_NAME $argv
end
