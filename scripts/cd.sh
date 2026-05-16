#!/usr/bin/bash

# Simulates the CD stage by loading shared logging, preparing state paths, and setting deployment variables.

# ----------------------------
# Functions
# ----------------------------

## Helper Functions

# If candidate artifacts do not exist, do not continue the remainder of the script
ensure_candidate_artifacts_exist() {
    log "DEBUG" "Function is ensure_candidate_artifacts_exist"

    if [[ ! -s "$CANDIDATE_IMAGE_TAG_FILE" || ! -s "$CANDIDATE_IMAGE_DIGEST_FILE" ]]; then
        log "FATAL" "Candidate artifacts do not exist!"
        exit 1
    fi
}

initialize_cd_pipeline() {
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
    log "DEBUG" "Function is initialize_cd_pipeline"
    log "INFO" "Loaded pipeline configuration"
    log "INFO" "Loaded logging library"
    log "DEBUG" "Writing pipeline logs to $LOG_FILE"

    mkdir -p "$STATE_PATH"
    log "DEBUG" "Created pipeline state directory: $STATE_PATH"
}

initialize_cd_config() {
    log "DEBUG" "Function is initialize_cd_config"

    # Fail fast if CI did not produce deployable candidate artifacts.
    ensure_candidate_artifacts_exist

    CANDIDATE_IMAGE_TAG="$(< "$CANDIDATE_IMAGE_TAG_FILE")"
    CANDIDATE_IMAGE_DIGEST="$(< "$CANDIDATE_IMAGE_DIGEST_FILE")"

    log "DEBUG" "candidate tag read as  $CANDIDATE_IMAGE_TAG"
    log "DEBUG" "candidate digest read as $CANDIDATE_IMAGE_DIGEST"


    # Ensures failure not prematurely thrown
    if [[ -f "$STABLE_IMAGE_DIGEST_FILE" ]]; then
        STABLE_IMAGE_DIGEST="$(< "$STABLE_IMAGE_DIGEST_FILE")"
    else
        STABLE_IMAGE_DIGEST=""
    fi

    log "DEBUG" "stable digest read as $STABLE_IMAGE_DIGEST"
    log "INFO" "Finished initializing the script"
}

# Roll back a failed deployment by removing the candidate container and image,
# then record the failure and clear stable state metadata.
cleanup_failed_deploy() {
    log "DEBUG" "cleanup_failed_deploy started!"

    # Remove the candidate container first so the failed deployment is no longer running.
     if ! docker container \
        remove "$CANDIDATE_CONTAINER_NAME" \
        --force \
        ; then

        # Continue cleanup even if the container is already gone.
        log "FATAL" "Could not remove Candidate Container $CANDIDATE_CONTAINER_NAME"
    fi

    log "DEBUG" "succesfully removed container $CANDIDATE_CONTAINER_NAME"

    # Remove the candidate image so the failed build is not reused accidentally.
    if ! docker image \
        rm \
        --force \
        "$CANDIDATE_IMAGE_DIGEST"; then

        log "FATAL" "Could not remove Candidate Image $CANDIDATE_IMAGE_TAG"
    fi

    log "DEBUG" "succesfully removed image with tag $CANDIDATE_IMAGE_TAG"


    # Record the failed deployment for later inspection.
    echo "$(date +"%Y-%m-%d %I:%M:%S %p") [FAILURE] $CANDIDATE_IMAGE_TAG deployment failed!" >> "$LAST_DEPLOY_STATUS_FILE"

    # Emit a final failure log for the pipeline output.
    log "FATAL" "$CANDIDATE_IMAGE_TAG deployment failed!"

    exit 1
}

# Remove stale docker images generated from the pipeline
cleanup_stale_images() {
    log "DEBUG" "Function is cleanup_stale_images"
    local -a all_digests=()

    # Collect every image digest carrying the pipeline label.
    mapfile -t all_digests < <(
        docker image ls \
            --filter "label=$PIPELINE_LABEL" \
            --all \
            --digests \
            --format "{{.Digest}}"
    )

    log "DEBUG" "Scanning pipeline image digests for cleanup"

    # Keep the candidate and stable images, delete everything else.
    for i in "${!all_digests[@]}"; do
        local cur_digest="${all_digests[$i]}"

        # Whitelist digests in candidate_image.digest and stable_image.digest
        if [[ "$cur_digest" == "$CANDIDATE_IMAGE_DIGEST" || "$cur_digest" == "$STABLE_IMAGE_DIGEST" ]]; then
            log "DEBUG" "Whitelisted image cur_digest[$i]: $cur_digest"
            continue
        fi

        # Delete all other digests
        log "INFO" "Deleting old pipeline image cur_digest[$i]: $cur_digest"
        if ! docker image rm --force "$cur_digest"; then
            log "ERROR" "Could not remove pipeline image $cur_digest"
        fi
    done
}

# Promote a validated candidate to stable and preserve the prior stable version when one exists.
cleanup_successful_deploy() {
    log "DEBUG" "Function is cleanup_successful_deploy"

    # If stable metadata already exists, this is an update rather than the first deploy.
    if [[ -f "$STABLE_IMAGE_DIGEST_FILE" && -f "$STABLE_IMAGE_TAG_FILE" ]]; then
        log "DEBUG" "Not a first deploy, stable artifacts exist!"

        if ! docker container remove "$STABLE_CONTAINER_NAME" --force; then
            log "FATAL" "Could not stop and remove current container!"
            cleanup_failed_deploy
        fi

        # at this point candidate is newly good deployed, stable is old deploy that we tore down
        cleanup_stale_images

        # Keep a record of the previous stable image before overwriting it.
        cp "$STABLE_IMAGE_DIGEST_FILE" "$PREVIOUS_IMAGE_DIGEST_FILE"
        cp "$STABLE_IMAGE_TAG_FILE" "$PREVIOUS_IMAGE_TAG_FILE"

        log "DEBUG" "Demoted stable artifacts to previous artifacts!"
    fi

    # Promote the candidate image metadata to stable on every successful deploy.
    cp "$CANDIDATE_IMAGE_DIGEST_FILE" "$STABLE_IMAGE_DIGEST_FILE"
    cp "$CANDIDATE_IMAGE_TAG_FILE" "$STABLE_IMAGE_TAG_FILE"

    log "DEBUG" "Promoted candidate artifacts to stable artifacts!"

    # Promote the running candidate container by renaming it to the stable name.
    if ! docker container rename "$CANDIDATE_CONTAINER_NAME" "$STABLE_CONTAINER_NAME"; then
        log "FATAL" "Could not rename candidate container to $STABLE_CONTAINER_NAME"
        cleanup_failed_deploy
    fi

    echo "$(date +"%Y-%m-%d %I:%M:%S %p") [SUCCESS] $CANDIDATE_IMAGE_TAG deployment succeeded!" >> "$LAST_DEPLOY_STATUS_FILE"

    # Remove lingering artifacts
    rm -f "$CANDIDATE_IMAGE_DIGEST_FILE" "$CANDIDATE_IMAGE_TAG_FILE"
    log "DEBUG" "Removed candidate artifacts"
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


# Start the candidate container from the image digest produced by CI so it can be validated before promotion.
run_candidate_container() {
    log "DEBUG" "Function is run_candidate_container"

    if ! docker run \
        --detach \
        --name "$CANDIDATE_CONTAINER_NAME" \
        "$CANDIDATE_IMAGE_DIGEST"; then

        # Log failures and exit.
        log "FATAL" "Candidate container $CANDIDATE_CONTAINER_NAME could not be started from image $CANDIDATE_IMAGE_DIGEST!"
        cleanup_failed_deploy
    fi

    log "INFO" "Candidate container $CANDIDATE_CONTAINER_NAME started from image $CANDIDATE_IMAGE_DIGEST"
}

# Run deployment tests against the candidate container after it becomes healthy.
run_deployment_tests() {
    log "DEBUG" "Function is run_deployment_tests"

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

run_candidate_container
run_deployment_tests
