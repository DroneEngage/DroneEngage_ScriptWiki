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
    log_message "${YELLOW}" "Usage: $0 <input_file> <output_file>"
    log_message "${YELLOW}" "  <input_file>  : Path to the input JSON file to read userName, accessCode, and auth_ip"
    log_message "${YELLOW}" "  <output_file> : Path to the output JSON file to update with those values"
    exit 1
}

# Check if correct number of arguments is provided
if [ $# -ne 2 ]; then
    log_message "${RED}" "Error: Incorrect number of arguments."
    usage
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    log_message "${RED}" "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Check if output file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    log_message "${RED}" "Error: Output file '$OUTPUT_FILE' not found."
    exit 1
fi

# Check if jq and sed are available
if ! command -v jq &> /dev/null; then
    log_message "${RED}" "Error: 'jq' command not found. Please install it."
    exit 1
fi
if ! command -v sed &> /dev/null; then
    log_message "${RED}" "Error: 'sed' command not found. Please install it."
    exit 1
fi

# Remove comments from input file for jq parsing
log_message "${BLUE}" "Processing input file '$INPUT_FILE'..."
TEMP_INPUT=$(mktemp)
# Strip single-line comments (//) and multi-line comments (/* ... */)
sed '/\/\*/,/\*\//d; s|//.*$||g' "$INPUT_FILE" > "$TEMP_INPUT" || {
    log_message "${RED}" "Error: Failed to process input file"
    rm -f "$TEMP_INPUT"
    exit 1
}

# Debug: Show the processed input file
log_message "${YELLOW}" "Processed input file content (for debugging):"
cat "$TEMP_INPUT" | while read -r line; do
    log_message "${YELLOW}" "  $line"
done

# Read userName, accessCode, and auth_ip from input file
USER_NAME=$(jq -r '.userName' "$TEMP_INPUT" 2>/dev/null)
ACCESS_CODE=$(jq -r '.accessCode' "$TEMP_INPUT" 2>/dev/null)
AUTH_IP=$(jq -r '.auth_ip' "$TEMP_INPUT" 2>/dev/null)

# Clean up temporary input file
rm -f "$TEMP_INPUT"

# Check if fields were successfully read
if [ -z "$USER_NAME" ] || [ "$USER_NAME" = "null" ] || \
   [ -z "$ACCESS_CODE" ] || [ "$ACCESS_CODE" = "null" ] || \
   [ -z "$AUTH_IP" ] || [ "$AUTH_IP" = "null" ]; then
    log_message "${RED}" "Error: Failed to read userName, accessCode, or auth_ip from '$INPUT_FILE'."
    exit 1
fi

log_message "${GREEN}" "Read userName='$USER_NAME', accessCode='$ACCESS_CODE', and auth_ip='$AUTH_IP' from '$INPUT_FILE'"

# Create a backup of the output file
BACKUP_FILE="${OUTPUT_FILE}.bak"
log_message "${BLUE}" "Creating backup of '$OUTPUT_FILE' to '$BACKUP_FILE'..."
cp "$OUTPUT_FILE" "$BACKUP_FILE" || {
    log_message "${RED}" "Error: Failed to create backup"
    exit 1
}
log_message "${GREEN}" "Backup created successfully"

# Update userName, accessCode, and auth_ip in the output file using sed
log_message "${BLUE}" "Updating '$OUTPUT_FILE' with userName='$USER_NAME', accessCode='$ACCESS_CODE', and auth_ip='$AUTH_IP'..."
# Replace userName (matches "userName" : "any_value",)
sed -i "s/\"userName\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"userName\" : \"$USER_NAME\"/" "$OUTPUT_FILE" || {
    log_message "${RED}" "Error: Failed to update userName"
    exit 1
}
# Replace accessCode (matches "accessCode" : "any_value",)
sed -i "s/\"accessCode\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"accessCode\" : \"$ACCESS_CODE\"/" "$OUTPUT_FILE" || {
    log_message "${RED}" "Error: Failed to update accessCode"
    exit 1
}
# Replace auth_ip (matches "auth_ip" : "any_value",)
sed -i "s/\"auth_ip\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"auth_ip\" : \"$AUTH_IP\"/" "$OUTPUT_FILE" || {
    log_message "${RED}" "Error: Failed to update auth_ip"
    exit 1
}
log_message "${GREEN}" "Output file updated successfully"

# Verify the changes
log_message "${BLUE}" "Verifying changes in '$OUTPUT_FILE'..."
if grep -q "\"userName\"[[:space:]]*:[[:space:]]*\"$USER_NAME\"" "$OUTPUT_FILE" && \
   grep -q "\"accessCode\"[[:space:]]*:[[:space:]]*\"$ACCESS_CODE\"" "$OUTPUT_FILE" && \
   grep -q "\"auth_ip\"[[:space:]]*:[[:space:]]*\"$AUTH_IP\"" "$OUTPUT_FILE"; then
    log_message "${GREEN}" "Verification successful: userName='$USER_NAME', accessCode='$ACCESS_CODE', auth_ip='$AUTH_IP'"
else
    log_message "${RED}" "Error: Verification failed. Check '$OUTPUT_FILE' manually."
    exit 1
fi

# Exit successfully
exit 0

