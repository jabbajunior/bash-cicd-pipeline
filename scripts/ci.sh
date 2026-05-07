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

# ----------------------------
# Main script
# ----------------------------

initialize_ci_pipeline
run_lint
run_tests