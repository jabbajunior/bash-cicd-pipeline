#!/usr/bin/bash

# TODO
# 1. Build the new Docker image.
# 2. Run in-process API tests against the new image.
# 3. Stop the currently running app container.
# 4. Start a new container from the new image.
# 5. Run deployment API tests against the running container.
# 6. Mark deployment as successful if all checks pass.

VERSION=$(date +%Y%m%d-%H%M%S)

# Building a new docker image
docker build \
    -t my-image:$VERSION \
    . \
    --progress=plain \
    --debug

