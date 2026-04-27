#!/usr/bin/bash

# TODO
# If fail at any point, stop execution of script and log an error somewhere
# Linting
# Testing 
# Merge PR

# Import in logging script
source "scripts/logging.sh" || {
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
}

LOG_FILE=$1
SCRIPT_PATH=$0

log "INFO" "has started execution"

# Linting
if ! uv run ruff check "app/"; then
    log "FATAL" "Linting Failed!"
    exit 2 # 2 = Linting
fi

log "INFO" "Linting passed"

# Testing
if ! uv run pytest; then
    log "FATAL" "Tests Failed!"
    exit 2 # 2 = Testing
fi

log "INFO" "Tests passed"

# TODO
# Run CI on git pull
# Potentially run tests in parallel via background job or something else NEED TO ENSURE FAILURE STOPS
#   m m