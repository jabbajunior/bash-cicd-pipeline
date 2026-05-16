#!/usr/bin/bash
# Logging library script that has consistent logging

if [[ -z "${LOG_PATH:-}" || -z "${LOG_FILE:-}" ]]; then
    echo "ERROR: logging config not loaded. Source config.sh before logging.sh" >&2
    exit 1
fi

mkdir -p "$LOG_PATH" || {
    echo "ERROR: could not create log directory: $LOG_PATH" >&2
    exit 1
}

#Use DEBUG liberally during development but sparingly in production. It’s perfect for tracing execution flow and variable values.
#Use INFO to track normal operation milestones - script start/end, major function completions, or configuration loading.
#Use WARN when something unexpected happens but the script can recover or continue.
#Use ERROR when an operation fails but the script can still perform other tasks.
#Use FATAL only for critical failures that prevent the script from functioning at all.

# Logging function
# Usage is log log_level "message"
log() {
    local log_level=$1  # A string representing the log level provided by the user when calling the function
    local message=$2  # A string representing the message provided by the user when calling the function
    
    local script_name=$(basename $SCRIPT_PATH)  # The name of the script that is running
    local timestamp=$(date +"%Y-%m-%d %I:%M:%S %p")  # The current date and time at the time the function is called
    echo "$timestamp [$log_level] [$script_name] $message" | tee -a "$LOG_FILE"
}
