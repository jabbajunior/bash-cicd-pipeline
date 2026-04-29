#!/usr/bin/bash

# This script executes a ci pipeline and is executed via ci.yml on a pull request being made or edited

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

# Linting
if ! uv run ruff check "app/"; then
    log "FATAL" "Linting Failed!"
    exit 2 # 2 = Linting
fi

log "INFO" "Linting passed"

# Testing

# Make these more specific so does not run entire test suite
# uv run pytest tests/test_X -v

if ! uv run pytest; then
    log "FATAL" "Tests Failed!"
    exit 3 # 3 = Testing
fi

log "INFO" "Tests passed"