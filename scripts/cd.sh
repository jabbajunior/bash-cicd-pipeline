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

# Roll back a failed deployment by removing the candidate container and image,
# then record the failure and clear stable state metadata.
cleanup_failed_deploy() {
    # Remove the candidate container first so the failed deployment is no longer running.
     if ! docker container \
        remove "$CANDIDATE_CONTAINER_NAME" \
        --force \
        ; then

        # Continue cleanup even if the container is already gone.
        log "FATAL" "Could not remove Candidate Container $CANDIDATE_CONTAINER_NAME"
    fi

    # Remove the candidate image so the failed build is not reused accidentally.
    if ! docker image \
        rm \
        --force \
        "$CANDIDATE_IMAGE_ID"; then

        log "FATAL" "Could not remove Candidate Image $CANDIDATE_IMAGE_TAG"
    fi

    # Record the failed deployment for later inspection.
    echo "$(date +"%Y-%m-%d %I:%M:%S %p") [FAILURE] $CANDIDATE_IMAGE_TAG deployment failed!" >> "$LAST_DEPLOY_STATUS_FILE"

    # Emit a final failure log for the pipeline output.
    log "FATAL" "$CANDIDATE_IMAGE_TAG deployment failed!"

    # Remove the stable image metadata so the next run does not treat it as current.
    rm "$STABLE_IMAGE_ID_FILE" "$STABLE_IMAGE_TAG_FILE"

    exit 1
}


cleanup_old_images() {
    # Cleans up older images generated from this file (via label) except for all files in the state directory


    # Cleans up all older images, except for the current stable image and a previous stable image

    # Scan the state directory for files and delete all 
    # Label all of our images

    
}

# Promote a validated candidate to stable and preserve the prior stable version when one exists.
cleanup_successful_deploy() {
    # If stable metadata already exists, this is an update rather than the first deploy.
    if [[ -f "$STABLE_IMAGE_ID_FILE" && -f "$STABLE_IMAGE_TAG_FILE" ]]; then
        if ! docker container remove "$STABLE_CONTAINER_NAME" --force; then
            log "FATAL" "Could not stop and remove current container!"
            cleanup_failed_deploy
        fi

        # Keep a record of the previous stable image before overwriting it.
        cp "$STABLE_IMAGE_ID_FILE" "$PREVIOUS_IMAGE_ID_FILE"
        cp "$STABLE_IMAGE_TAG_FILE" "$PREVIOUS_IMAGE_TAG_FILE"
    fi

    # Promote the candidate image metadata to stable on every successful deploy.
    cp "$CANDIDATE_IMAGE_ID_FILE" "$STABLE_IMAGE_ID_FILE"
    cp "$CANDIDATE_IMAGE_TAG_FILE" "$STABLE_IMAGE_TAG_FILE"

    # Promote the running candidate container by renaming it to the stable name.
    docker container rename "$CANDIDATE_CONTAINER_NAME" "$STABLE_CONTAINER_NAME"

    echo "$(date +"%Y-%m-%d %I:%M:%S %p") [SUCCESS] $CANDIDATE_IMAGE_TAG deployment succeeded!" >> "$LAST_DEPLOY_STATUS_FILE"
    cleanup_old_images
}

# Wait for the candidate server to fbecome healthy before running tests.
wait_for_healthy_candidate() {
    local max_attempts=15
    local cur_attempt=1

    log "INFO" "Waiting for candidate server to become ready"

    # Loop until max_attempts to determine if the candidate server is online.
    while [[ "$cur_attempt" -le "$max_attempts" ]]; do

        if docker exec \
            "$CANDIDATE_CONTAINER_NAME" \
            curl --fail --silent "http://localhost:8000/health" >/dev/null; then

            log "INFO" "Candidate server is ready"
            return 0
        fi

        log "INFO" "Candidate server not ready yet. Attempt $((cur_attempt++))/$max_attempts"
        sleep 2
    done

    log "FATAL" "Candidate server did not become ready in time"
    docker ps --filter "name=$CANDIDATE_CONTAINER_NAME"
    docker logs "$CANDIDATE_CONTAINER_NAME" --tail 100
    return 1
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