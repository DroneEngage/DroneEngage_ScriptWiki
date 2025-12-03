#!/bin/bash

# =============================================================================
# Backup DroneEngage Configuration Files
# =============================================================================
# This script backs up all .json configuration files from /home/pi/drone_engage
# to a timestamped folder structure under drone_engage_config_backups
# AUTHOR: Mohammad Hefny
# DATE:   Dec 03 2025
# =============================================================================

# Configuration
SOURCE_DIR="/home/pi/drone_engage"
BACKUP_PARENT_DIR="/home/pi/drone_engage_config_backups"

# Get current date for folder naming
DATE_FOLDER=$(date +"%Y-%m-%d_%H-%M-%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory $SOURCE_DIR does not exist."
    exit 1
fi

# Create backup parent directory if it doesn't exist
if [ ! -d "$BACKUP_PARENT_DIR" ]; then
    log_info "Creating backup parent directory: $BACKUP_PARENT_DIR"
    mkdir -p "$BACKUP_PARENT_DIR"
fi

# Create date-based backup folder
BACKUP_DATE_DIR="$BACKUP_PARENT_DIR/$DATE_FOLDER"
log_info "Creating backup folder: $BACKUP_DATE_DIR"
mkdir -p "$BACKUP_DATE_DIR"

# Counter for backed up files
BACKUP_COUNT=0

# Find all .json files in source directory and its subdirectories
log_info "Searching for .json files in $SOURCE_DIR..."

while IFS= read -r -d '' json_file; do
    # Get the relative path from SOURCE_DIR
    relative_path="${json_file#$SOURCE_DIR/}"
    
    # Get the directory part (module subfolder)
    module_dir=$(dirname "$relative_path")
    
    # Get the filename
    filename=$(basename "$json_file")
    
    # Create the corresponding backup directory structure
    if [ "$module_dir" != "." ]; then
        backup_module_dir="$BACKUP_DATE_DIR/$module_dir"
    else
        backup_module_dir="$BACKUP_DATE_DIR"
    fi
    
    # Create module directory if it doesn't exist
    mkdir -p "$backup_module_dir"
    
    # Copy the file
    sudo cp "$json_file" "$backup_module_dir/$filename"
    
    if [ $? -eq 0 ]; then
        log_info "Backed up: $relative_path"
        ((BACKUP_COUNT++))
    else
        log_error "Failed to backup: $relative_path"
    fi
    
done < <(find "$SOURCE_DIR" -type f -name "*.json" -print0)

# Summary
echo ""
echo "============================================="
if [ $BACKUP_COUNT -gt 0 ]; then
    log_info "Backup complete! $BACKUP_COUNT file(s) backed up."
    log_info "Backup location: $BACKUP_DATE_DIR"
    
    # Prune old backups, keep only 3 most recent
    log_info "Pruning old backups (keeping 3 most recent)..."
    ls -dt "$BACKUP_PARENT_DIR"/*/ 2>/dev/null | tail -n +4 | xargs -r rm -rf
else
    log_warn "No .json files found to backup."
    # Remove empty date folder if no files were backed up
    rmdir "$BACKUP_DATE_DIR" 2>/dev/null
fi
echo "============================================="

exit 0
