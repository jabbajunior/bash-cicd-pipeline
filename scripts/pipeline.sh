#!/usr/bin/bash

# Bootstrap fatal logger used before logging.sh is available.
fatal() {
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
}

# Preserve the original working directory so it can be restored before exit.
PREVIOUS_PATH="$(pwd)"

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

# Switch to the project root so relative paths behave consistently.
if ! cd "$PROJECT_ROOT"; then
    log "FATAL" "could not cd into script directory: $PROJECT_ROOT"
    exit 1
fi

log "INFO" "switched to project root directory"

# Execute ci.sh
./scripts/ci.sh $LOG_FILE
# Execute cd.sh

# 
