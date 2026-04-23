#!/usr/bin/bash

# Preserve the original working directory so it can be restored before exit.
PREVIOUS_PATH="$(pwd)"

# Resolve paths relative to this script.
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load shared logging helpers.
source "$SCRIPT_DIR/logging.sh"

# Switch to the script directory so relative paths behave consistently.
if ! cd "$SCRIPT_DIR"; then
    log "FATAL" "Could not cd into script directory!"
    exit 1
fi


log "INFO" "this is a test"
echo 
echo
echo "script path: $SCRIPT_PATH"
echo "script dir: $SCRIPT_DIR"
echo "project_root: $PROJECT_ROOT"


# Execute ci.sh

# Execute cd.sh

# 
