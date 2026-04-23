#!/usr/bin/bash

# TODO
# If fail at any point, stop execution of script and log an error somewhere
# Linting
# Testing 
# Merge PR
# Not sure if have to build a new executable for docker image
# Build new docker image

SCRIPT_PATH="${BASH_SOURCE[0]}" # Grabs the current relative path of this script
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)" # Gets the absolute path of the scripts folder
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")" # Gets the absolute path of the root project folder

cd $PROJECT_ROOT

# Linting
if ! uv run ruff check "$PROJECT_ROOT/app"; then
    echo "$(date): linting failed" >> "$PROJECT_ROOT/logs/pipeline.log" # TODO: Replace this later with a centralized logger
    echo "Linting failed!"
    exit 1 # 1 = Linting
fi

# Testing
if ! uv run pytest; then
    echo "$(date): tests failed" >> "$PROJECT_ROOT/logs/pipeline.log" # TODO: Replace this later with a centralized logger
    echo "Tests failed!"
    exit 2 # 2 = Testing
fi



# would want the script to be resilient not dependent on you running it in a certain directory
# pipeline.sh 