
function gemini-ai-key
    set -l key (gcloud services api-keys get-key-string --project acs-senseco-ai-playground bdc2ab7d-5484-4e9a-8e9c-1989036097c3 | string split ' ' -f2)
    set -gx GEMINI_API_KEY $key
end

set -gx CLAUDE_CODE_USE_VERTEX 1
set -gx CLOUD_ML_REGION us-east5
set -gx ANTHROPIC_VERTEX_PROJECT_ID itpc-gcp-hybrid-pe-eng-claude
