#!/usr/bin/bash

# Simulates the CI stage by loading shared logging, linting the app, and running the test suite.
# It then builds a candidate Docker image for later deployment.

# ----------------------------
# Functions
# ----------------------------

initialize_ci_pipeline() {
    # Make the script path available to the shared logger.
    export SCRIPT_PATH="${BASH_SOURCE[0]}"

    # Load the shared logging helpers after SCRIPT_PATH is set.
    if ! source "./scripts/logging.sh"; then
        echo "[FATAL] Could not load logging.sh"
        exit 1
    fi

    log "INFO" "Started Execution"
    log "INFO" "Loaded logging library"

    LABEL="test-pipeline"

    # Build the candidate Docker image after linting and tests pass.
    STATE_PATH="./state"
    CANDIDATE_IMAGE_ID_FILE="$STATE_PATH/candidate_image.id"
    CANDIDATE_IMAGE_TAG_FILE="$STATE_PATH/candidate_image.tag"
    LABEL_FILE="$STATE_PATH/label.txt"
}

run_lint() {
    # Run the linter on the application code.
    if ! uv run ruff check "app/"; then
        log "FATAL" "Linting Failed!"
        exit 1
    fi

    log "INFO" "Linting passed"
}

run_tests() {
    # Run the test suite against the application.
    if ! uv run pytest tests/test_combined.py --api-target=inprocess --verbose; then
        log "FATAL" "Unit tests failed"
        exit 1
    fi

    log "INFO" "Tests passed"
}

run_build() {
    # Use UTC so build tags are consistent across local runs and CI runners.
    local image_version
    image_version="$(date -u +"%Y-%m-%dT%H-%M-%SZ")"

    # Tag each build with a unique timestamp.
    local image_name="my-image"
    local tag_name="$image_name:$image_version"

    # Build the image and write the image ID to the state file.
    if ! docker image build \
        --tag "$tag_name" \
        --iidfile "$CANDIDATE_IMAGE_ID_FILE" \
        --progress=plain \
        --label="$LABEL" \
        .; then
        
        # Removes any dangling images left behind
        docker image prune -f

        # Log failures and exit
        log "FATAL" "Candidate image could not be built!"
        exit 1
    fi

    printf '%s\n' "$tag_name" > "$CANDIDATE_IMAGE_TAG_FILE"
    printf '%s\n' "$LABEL" > "$LABEL_FILE"
    log "INFO" "Built image $tag_name with image ID $(cat "$CANDIDATE_IMAGE_ID_FILE")"
}


# ----------------------------
# Main script
# ----------------------------

initialize_ci_pipeline
run_lint
run_tests
run_build
