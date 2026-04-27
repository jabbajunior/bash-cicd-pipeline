#!/usr/bin/bash

VERSION=$(date +%Y%m%d-%H%M%S)
CONTAINER_NAME="my-app"
IMAGE_NAME="my-image"
HOST_PORT="8000"
CONTAINER_PORT="8000"

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

# will have an error first time run, since no old container to remove

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