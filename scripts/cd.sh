#!/usr/bin/bash

# Simulates the CD stage by loading shared logging, preparing state paths, and setting deployment variables.

# ----------------------------
# Functions
# ----------------------------

## Helper Functions

initialize_cd_pipeline() {
    # Make the script path available to the shared logger.
    export SCRIPT_PATH="${BASH_SOURCE[0]}"

    # Load the shared logging helpers after SCRIPT_PATH is set.
    if ! source "./scripts/logging.sh"; then
        echo "[FATAL] Could not load logging.sh"
        exit 1
    fi

    log "INFO" "Started Execution"
    log "INFO" "Loaded logging library"
}

initialize_cd_config() {
    # Deployment state files track image IDs for rollback decisions.
    STATE_PATH="./state"

    CANDIDATE_IMAGE_ID_FILE="$STATE_PATH/candidate_image.id"
    CANDIDATE_IMAGE_TAG_FILE="$STATE_PATH/candidate_image.tag"
    STABLE_IMAGE_ID_FILE="$STATE_PATH/stable_image.id"
    STABLE_IMAGE_TAG_FILE="$STATE_PATH/stable_image.tag"
    PREVIOUS_IMAGE_ID_FILE="$STATE_PATH/previous_image.id"
    PREVIOUS_IMAGE_TAG_FILE="$STATE_PATH/previous_image.tag"

    LAST_DEPLOY_STATUS_FILE="$STATE_PATH/last_deploy_status.txt"

    STABLE_CONTAINER_NAME="my-app"
    CANDIDATE_CONTAINER_NAME="my-app-dev"
    HOST_PORT="8000"

    CANDIDATE_IMAGE_TAG="$(< "$CANDIDATE_IMAGE_TAG_FILE")"
    CANDIDATE_IMAGE_ID="$(< "$CANDIDATE_IMAGE_ID_FILE")"

    log "INFO" "Finished initializing the script"
}

## Workflow Functions


# Start the candidate container from the image ID produced by CI so it can be validated before promotion.
run_candidate_container() {
    if ! docker run \
        --detach \
        --name "$CANDIDATE_CONTAINER_NAME" \
        "$CANDIDATE_IMAGE_ID"; then

        # Log failures and exit.
        log "FATAL" "Candidate container $CANDIDATE_CONTAINER_NAME could not be started from image $CANDIDATE_IMAGE_ID!"
        cleanup_failed_deploy
    fi

    log "INFO" "Candidate container $CANDIDATE_CONTAINER_NAME started from image $CANDIDATE_IMAGE_ID"
}

# Run deployment tests against the candidate container after it becomes healthy.
run_deployment_tests() {
    if ! wait_for_healthy_candidate; then
        log "FATAL" "Candidate Server is not healthy!"
        cleanup_failed_deploy
    fi

    # Run the deployment API tests against the running container.
    if ! docker exec \
        "$CANDIDATE_CONTAINER_NAME" \
        uv run pytest \
        tests/test_combined.py \
        --api-target=live \
        --base-url="http://localhost:${HOST_PORT}" \
        --verbose; then

        # Log failures and cleanup
        log "FATAL" "Candidate container $CANDIDATE_CONTAINER_NAME did not pass the testing suite!"
        log "DEBUG" "Rollback initiated!"

        cleanup_failed_deploy
    fi

    
    log "INFO" "Candidate container $CANDIDATE_CONTAINER_NAME passed the automated testing"
    cleanup_successful_deploy
}


# ----------------------------
# Main script
# ----------------------------

initialize_cd_pipeline
initialize_cd_config

# TODO testing purposes only
#docker container prune -f

run_candidate_container
run_deployment_tests
