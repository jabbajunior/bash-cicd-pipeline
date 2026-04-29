#!/usr/bin/bash

# This script executes a cd pipeline via cd.yml after a pull request has been merged

# Bootstrap fatal logger used before logging.sh is available.
fatal() {
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
}

# Resolve paths relative to this script.
SCRIPT_PATH="${BASH_SOURCE[0]}"

if [[ "$SCRIPT_PATH" != */* ]]; then
    SCRIPT_PATH="$(command -v "$SCRIPT_PATH")" || fatal "could not resolve script path"
fi


# Resolve absolute script and project directories
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)" || fatal "could not resolve script directory"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)" || fatal "could not resolve project root"

# Load shared logging helpers as soon as SCRIPT_DIR is known.
source "$SCRIPT_DIR/logging.sh" || fatal "could not load logging.sh"

log "INFO" "Started Execution"
log "INFO" "Loaded logging library"
log "DEBUG" "PROJECT_ROOT: $PROJECT_ROOT"

# Switch to the project root so relative paths behave consistently.
if ! cd "$PROJECT_ROOT"; then
    log "FATAL" "could not cd into script directory: $PROJECT_ROOT"
    exit 1
fi

log "INFO" "Changed path to project root directory"


VERSION=$(date +%Y%m%d-%H%M%S)
CONTAINER_NAME="my-app"
IMAGE_NAME="my-image"
HOST_PORT="8000"
CONTAINER_PORT="8000"

# TODO Add explicit logging and rollback support on docker failures

# 1. Build the new Docker image.
docker build \
    --tag "$IMAGE_NAME:$VERSION" \
    . \
    --progress=plain \
    --debug

# 2. Run in-process API tests in a temporary container from the new image.
docker run \
    --rm \
    "$IMAGE_NAME:$VERSION" \
    uv run pytest \
    tests/test_inprocess_api.py \
    --verbose

# 3. Stop and remove the currently running app container.
docker rm \
    --force \
    "$CONTAINER_NAME"
    # COnsider redirecting errors?

# TODO will have an error first time run, since no old container to remove

# 4. Start a new container from the new image.
docker run \
    --detach \
    --name "$CONTAINER_NAME" \
    --publish "$HOST_PORT:$CONTAINER_PORT" \
    "$IMAGE_NAME:$VERSION"


# 5. Run deployment API tests against the running container.
docker exec \
    --env BASE_URL=http://localhost:8000 \
    "$CONTAINER_NAME" \
    uv run pytest \
    tests/test_deployment_api.py \
    --verbose