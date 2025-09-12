#!/bin/bash

# Define color codes for consistent console output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Log message function for consistent colored output
log_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to kill processes by pattern until none remain
kill_process() {
    local pattern=$1
    local process_name=$2
    local max_attempts=5
    local attempt=1

    log_message "${BLUE}" "Terminating $process_name processes..."

    while [ $attempt -le $max_attempts ]; do
        pids=$(pgrep -f "$pattern")
        if [ -z "$pids" ]; then
            log_message "${GREEN}" "No $process_name processes found"
            return 0
        fi

        for pid in $pids; do
            kill -TERM "$pid" 2>/dev/null
            log_message "${GREEN}" "$process_name (PID: $pid) terminated"
        done

        # Wait briefly to allow processes to terminate
        sleep 0.5

        # Check if any processes still exist
        if ! pgrep -f "$pattern" > /dev/null; then
            log_message "${GREEN}" "All $process_name processes terminated"
            return 0
        fi

        log_message "${YELLOW}" "Attempt $attempt: Some $process_name processes still running, retrying..."
        ((attempt++))
    done

    log_message "${RED}" "Failed to terminate all $process_name processes after $max_attempts attempts"
    return 1
}

# Terminate all SITL arducopter instances
kill_process "arducopter" "SITL arducopter"

# Terminate all de_comm instances
kill_process "de_comm" "de_comm"

# Terminate all de_mavlink instances
kill_process "de_ardupilot" "de_mavlink"

# Wait briefly to ensure all processes are fully terminated
log_message "${BLUE}" "Waiting for final process termination..."
sleep 1
log_message "${GREEN}" "Process termination wait complete"

# Verify no processes are still running
log_message "${BLUE}" "Verifying termination..."
if pgrep -f "arducopter" > /dev/null || pgrep -f "de_comm" > /dev/null || pgrep -f "de_ardupilot" > /dev/null; then
    log_message "${RED}" "Some processes may still be running. Please check manually."
    exit 1
else
    log_message "${GREEN}" "All targeted processes successfully terminated"
fi

# Exit successfully
exit 0
