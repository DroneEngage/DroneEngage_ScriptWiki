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

# Function to display usage
usage() {
    log_message "${YELLOW}" "Usage: $0 [-a <application_name> | -p <pid>]"
    log_message "${YELLOW}" "  -a <application_name> : Check ports for processes matching the application name"
    log_message "${YELLOW}" "  -p <pid>              : Check ports for a specific process ID"
    exit 1
}

# Check if required tools are installed
for cmd in ss lsof pgrep; do
    if ! command -v "$cmd" &> /dev/null; then
        log_message "${RED}" "Error: $cmd is not installed. Please install it."
        exit 1
    fi
done

# Parse command-line arguments
while getopts "a:p:" opt; do
    case $opt in
        a) APP_NAME="$OPTARG" ;;
        p) PID="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure exactly one of -a or -p is provided
if [ -z "$APP_NAME" ] && [ -z "$PID" ]; then
    log_message "${RED}" "Error: You must specify either an application name (-a) or a PID (-p)."
    usage
elif [ -n "$APP_NAME" ] && [ -n "$PID" ]; then
    log_message "${RED}" "Error: Please specify either an application name (-a) or a PID (-p), not both."
    usage
fi

# Function to check ports for a given PID
check_ports_by_pid() {
    local pid=$1
    # Verify PID exists
    if ! ps -p "$pid" > /dev/null; then
        log_message "${RED}" "Error: No process found with PID $pid."
        exit 1
    fi
    local process_name
    process_name=$(ps -p "$pid" -o comm=)
    log_message "${BLUE}" "Checking open ports for PID $pid ($process_name)..."

    # Use ss to find open ports
    log_message "${YELLOW}" "TCP and UDP ports opened by PID $pid:"
    ss -tulnp | grep "pid=$pid" | while read -r line; do
        proto=$(echo "$line" | awk '{print $1}')
        local_addr=$(echo "$line" | awk '{print $5}')
        log_message "${GREEN}" "Protocol: $proto, Local Address: $local_addr, PID: $pid ($process_name)"
    done

    # Use lsof as an alternative to confirm
    lsof -i -P -n -p "$pid" 2>/dev/null | grep LISTEN | while read -r line; do
        proto=$(echo "$line" | awk '{print $8}' | cut -d: -f1)
        port=$(echo "$line" | awk '{print $9}' | cut -d: -f2)
        log_message "${GREEN}" "Protocol: $proto, Port: $port, PID: $pid ($process_name) [via lsof]"
    done

    # Check if any ports were found
    if ! ss -tulnp | grep "pid=$pid" > /dev/null && ! lsof -i -P -n -p "$pid" | grep LISTEN > /dev/null; then
        log_message "${YELLOW}" "No open ports found for PID $pid."
    fi
}

# Function to check ports for a given application name
check_ports_by_app() {
    local app_name=$1
    log_message "${BLUE}" "Checking open ports for application '$app_name'..."

    # Find PIDs matching the application name
    pids=$(pgrep -f "$app_name")
    if [ -z "$pids" ]; then
        log_message "${RED}" "Error: No processes found for application '$app_name'."
        exit 1
    fi

    # Iterate over each PID
    for pid in $pids; do
        check_ports_by_pid "$pid"
    done
}

# Main logic
if [ -n "$APP_NAME" ]; then
    check_ports_by_app "$APP_NAME"
elif [ -n "$PID" ]; then
    check_ports_by_pid "$PID"
fi

log_message "${GREEN}" "Port checking complete"
exit 0

