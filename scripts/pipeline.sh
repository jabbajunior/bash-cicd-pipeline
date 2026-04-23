#!/usr/bin/bash

# Resolves this script's location and derives the project root from it
get_absolute_path () {
    # Path of current script
    SCRIPT_PATH="${BASH_SOURCE[0]}"

    # Directory containing this script 
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

    # Project Root Directory
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

    # Change into the script directory, so later path operations are relative
    if ! cd "$SCRIPT_DIR"; then
        #log error via error redirection
        exit 1
    fi

    return 0
}

# Save the caller's working directory so it can be restored later
PREVIOUS_PATH="$(pwd)" # Restore to this later

get_absolute_path


echo 
echo
echo "script path: $SCRIPT_PATH"
echo "script dir: $SCRIPT_DIR"
echo "project_root: $PROJECT_ROOT"



#find $(pwd) -name "bash-cicd-pipeline"

#realpath /pipeline.sh

# Execute ci.sh

# Execute cd.sh

# 
