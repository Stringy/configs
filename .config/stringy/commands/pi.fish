# --- Pi environment ---

function __pi_run --description "Run Pi with an isolated profile"
    set -l profile $argv[1]
    set -e argv[1]

    set -lx PI_CODING_AGENT_DIR $HOME/.pi/$profile
    set -lx PI_TELEMETRY 0
    set -lx PI_SKIP_VERSION_CHECK 1

    if test "$profile" = work
        set -lx GOOGLE_CLOUD_PROJECT $ANTHROPIC_VERTEX_PROJECT_ID
        set -lx VERTEX_LOCATION $CLOUD_ML_REGION
        set -lx GOOGLE_APPLICATION_CREDENTIALS $HOME/.config/gcloud/application_default_credentials.json
        if test -r $HOME/.config/secrets/openai
            set -lx OPENAI_API_KEY (cat $HOME/.config/secrets/openai)
        end
    else
        set -lx GOOGLE_CLOUD_PROJECT
        set -lx VERTEX_LOCATION
        set -lx GOOGLE_APPLICATION_CREDENTIALS
    end

    command pi $argv
end

function pi --description "Run Pi with the work or personal profile"
    if at_work
        __pi_run work $argv
    else
        __pi_run personal $argv
    end
end

function pi-personal --description "Run Pi with the personal profile"
    __pi_run personal $argv
end

function pi-work --description "Run Pi with the work profile"
    __pi_run work $argv
end

function pi-resume --description "Resume the most recent Pi session"
    pi --continue $argv
end

function pi-sessions --description "Browse Pi sessions for the current project"
    pi --resume $argv
end

alias picode=pi
alias pir=pi-resume
alias pis=pi-sessions
