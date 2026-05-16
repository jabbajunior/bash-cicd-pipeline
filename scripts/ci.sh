#!/usr/bin/bash

# Simulates the CI stage by loading shared logging, linting the app, and running the test suite.
# It then builds a candidate Docker image for later deployment.

# ----------------------------
# Functions
# ----------------------------

initialize_ci_pipeline() {
    # Make the script path available to the shared logger.
    export SCRIPT_PATH="${BASH_SOURCE[0]}"

    # Load configuration first so the logger can use configured paths.
    if ! source "./scripts/config.sh"; then
        echo "[FATAL] Could not load config.sh"
        exit 1
    fi

    # Load the shared logging helpers after SCRIPT_PATH is set.
    if ! source "$LOGGING_SCRIPT_PATH"; then
        echo "[FATAL] Could not load $LOGGING_SCRIPT_PATH"
        exit 1
    fi

    log "INFO" "Started Execution"
    log "DEBUG" "Function is initialize_ci_pipeline"
    log "INFO" "Loaded pipeline configuration"
    log "INFO" "Loaded logging library"
    log "DEBUG" "Writing pipeline logs to $LOG_FILE"

    mkdir -p "$STATE_PATH"
    log "DEBUG" "Created pipeline state directory: $STATE_PATH"
}

run_lint() {
    log "DEBUG" "Function is run_lint"
    # Run the linter on the application code.
    if ! uv run ruff check "app/"; then
        log "FATAL" "Linting Failed!"
        exit 1
    fi

    log "INFO" "Linting passed"
}

run_tests() {
    log "DEBUG" "Function is run_tests"

    # Run the test suite against the application.
    if ! uv run pytest tests/test_combined.py --api-target=inprocess --verbose; then
        log "FATAL" "Unit tests failed"
        exit 1
    fi

    log "INFO" "Tests passed"
}

run_build() {
    log "DEBUG" "Function is run_build"

    # Use UTC so build tags are consistent across local runs and CI runners.
    local image_version
    image_version="$(date -u +"%Y-%m-%dT%H-%M-%SZ")"

    # Tag each build with a unique timestamp.
    local tag_name="$IMAGE_NAME:$image_version"

    # Build the image and write the digest to the state file.
    if ! docker image build \
        --tag "$tag_name" \
        --iidfile "$CANDIDATE_IMAGE_DIGEST_FILE" \
        --progress=plain \
        --label "$PIPELINE_LABEL" \
        .; then
        
        # Removes any dangling images left behind
        docker image prune -f

        # Log failures and exit
        log "FATAL" "Candidate image could not be built!"
        exit 1
    fi

    printf '%s\n' "$tag_name" > "$CANDIDATE_IMAGE_TAG_FILE"
    log "DEBUG" "Wrote $tag_name to $CANDIDATE_IMAGE_TAG_FILE" 
    log "INFO" "Built image $tag_name with image digest $(cat "$CANDIDATE_IMAGE_DIGEST_FILE")"
}


# ----------------------------
# Main script
# ----------------------------

initialize_ci_pipeline
run_lint
run_tests
run_build

log "DEBUG" "Finished executing ci.sh"
