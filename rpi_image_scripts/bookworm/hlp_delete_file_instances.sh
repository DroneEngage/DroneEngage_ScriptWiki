#!/bin/bash

# USAGE EXAMPLE: sudo ./delete_file_instances.sh example.txt

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
    log_message "${YELLOW}" "Usage: $0 <filename>"
    log_message "${YELLOW}" "  <filename> : The name of the file to search for and delete"
    exit 1
}

# Check if filename is provided
if [ $# -ne 1 ]; then
    log_message "${RED}" "Error: Please provide a filename to search for and delete."
    usage
fi

FILENAME="$1"

# Check if find command is available
if ! command -v find &> /dev/null; then
    log_message "${RED}" "Error: 'find' command not found. Please install it."
    exit 1
fi

# Search for the file across all mounted filesystems
log_message "${BLUE}" "Searching for all instances of '$FILENAME'..."
FOUND_FILES=$(find / -type f -name "$FILENAME" 2>/dev/null)
if [ -z "$FOUND_FILES" ]; then
    log_message "${YELLOW}" "No instances of '$FILENAME' found."
    exit 0
fi

# Count found files
FILE_COUNT=$(echo "$FOUND_FILES" | wc -l)
log_message "${GREEN}" "Found $FILE_COUNT instance(s) of '$FILENAME':"
echo "$FOUND_FILES" | while read -r file; do
    log_message "${GREEN}" "  $file"
done

# Prompt for confirmation before deletion
log_message "${YELLOW}" "Do you want to delete all $FILE_COUNT instance(s) of '$FILENAME'? (y/N)"
read -r RESPONSE
if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
    log_message "${YELLOW}" "Operation canceled. No files were deleted."
    exit 0
fi

# Delete each found file
log_message "${BLUE}" "Deleting all instances of '$FILENAME'..."
echo "$FOUND_FILES" | while read -r file; do
    if rm -f "$file" 2>/dev/null; then
        log_message "${GREEN}" "Deleted: $file"
    else
        log_message "${RED}" "Failed to delete: $file (check permissions or file status)"
    fi
done

# Verify deletion
log_message "${BLUE}" "Verifying deletion..."
REMAINING_FILES=$(find / -type f -name "$FILENAME" 2>/dev/null)
if [ -z "$REMAINING_FILES" ]; then
    log_message "${GREEN}" "All instances of '$FILENAME' successfully deleted."
else
    log_message "${RED}" "Some instances of '$FILENAME' could not be deleted:"
    echo "$REMAINING_FILES" | while read -r file; do
        log_message "${RED}" "  $file"
    done
    exit 1
fi

# Exit successfully
exit 0

