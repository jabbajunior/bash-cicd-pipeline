#!/usr/bin/bash

get_absolute_path () {
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

    cd $SCRIPT_DIR # If fail, exit script and log error

    return 0
}



PREVIOUS_PATH="$(pwd)" # Restore to this later

# Determining the location of root folder so portable on any system
SCRIPT_PATH=
SCRIPT_DIR=
PROJECT_ROOT=

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
