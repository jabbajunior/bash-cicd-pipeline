#!/usr/bin/bash

# Shared configuration for the CI and CD pipeline scripts.

# Keep pipeline state outside the repo checkout when PIPELINE_STATE_PATH is set
readonly STATE_PATH="${PIPELINE_STATE_PATH:-./state}"
readonly PIPELINE_LABEL="com.example.pipeline=test-pipeline"

readonly IMAGE_NAME="my-image"

readonly CANDIDATE_IMAGE_DIGEST_FILE="$STATE_PATH/candidate_image.digest"
readonly CANDIDATE_IMAGE_TAG_FILE="$STATE_PATH/candidate_image.tag"

readonly STABLE_IMAGE_DIGEST_FILE="$STATE_PATH/stable_image.digest"
readonly STABLE_IMAGE_TAG_FILE="$STATE_PATH/stable_image.tag"

readonly PREVIOUS_IMAGE_DIGEST_FILE="$STATE_PATH/previous_image.digest"
readonly PREVIOUS_IMAGE_TAG_FILE="$STATE_PATH/previous_image.tag"

readonly LAST_DEPLOY_STATUS_FILE="$STATE_PATH/last_deploy_status.txt"

readonly STABLE_CONTAINER_NAME="my-app"
readonly CANDIDATE_CONTAINER_NAME="my-app-dev"

readonly HOST_PORT="8000"
