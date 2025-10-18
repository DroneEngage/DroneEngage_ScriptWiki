#!/bin/bash

# Define the repository path and necessary colors (assuming $GREEN, $BLUE, $NC are defined elsewhere, 
# but including them here for robustness if not)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "$BLUE Updating DroneEngage Web Client $NC"

# --- Configuration Backup Setup (Executed in $HOME) ---

# 1. Define the directory for config file backup outside the repo
CONFIG_BACKUP_DIR="OLD_WEBCLIENT_SETTINGS"
echo -e "$BLUE Backing up config.json to $CONFIG_BACKUP_DIR/ $NC"

# Ensure the backup directory exists in the user's home folder
mkdir -p $HOME/$CONFIG_BACKUP_DIR

# Copy the existing config file (if it exists)
cp $HOME/droneengage_webclient/build/config.json $HOME/$CONFIG_BACKUP_DIR/config.json 2>/dev/null || \
  echo -e "$RED config.json not found in build directory, skipping config backup. $NC"

# 2. Change to the project directory
pushd $HOME/droneengage_webclient

# 3. Stash any local changes before pulling
echo -e "$BLUE Stashing local changes... $NC"

# Get count of stashes before operation (suppress common 'no stashes' error)
STASH_COUNT_BEFORE=$(git stash list 2>/dev/null | wc -l)

# Use git stash push to save changes (suppress output but preserve exit status for now)
git stash push --include-untracked -m "Pre-update stash $(date +%Y%m%d%H%M)" 2>/dev/null

# Get count of stashes after operation
STASH_COUNT_AFTER=$(git stash list 2>/dev/null | wc -l)

# Check if a new stash was successfully created (count increased)
if [ "$STASH_COUNT_AFTER" -le "$STASH_COUNT_BEFORE" ]; then
    echo -e "$BLUE No new changes stashed. Continuing with pull... $NC"
else
    STASH_REF="stash@{0}" # The newest stash is always at index 0 after a push
    
    # 4. Define and create the destination directory for stashed files (relative to project folder)
    STASH_EXTRACT_DIR="local_changes_backup"
    echo -e "$BLUE Extracting stashed files to '$STASH_EXTRACT_DIR/'... $NC"
    
    # Ensure the backup directory for stashed files exists inside the project folder
    mkdir -p $STASH_EXTRACT_DIR
    
    # --- Robust Method: Create a temporary branch to extract stashed files ---
    
    STASH_BRANCH="stash_temp_$(date +%s)"
    
    # 1. Create a branch from the stash commit and check it out (restores stashed working tree)
    git stash branch "$STASH_BRANCH" $STASH_REF 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create temporary stash branch. Local changes will be kept in the stash list for manual recovery. $NC"
        # Skip the copy/drop and keep the reference in the stash list
    else
        # 2. Copy the contents of the stashed working tree into the backup directory.
        echo -e "$BLUE Copying stashed files to $STASH_EXTRACT_DIR/ $NC"
        # Use rsync to copy all files excluding the .git folder and the destination folder itself.
        rsync -a --exclude='.git' --exclude="$STASH_EXTRACT_DIR" ./ $STASH_EXTRACT_DIR/
        
        # 3. Clean up: switch back to 'release' branch and delete temp branch
        echo -e "$BLUE Cleaning up temporary branch $STASH_BRANCH $NC"
        git checkout release
        git branch -D "$STASH_BRANCH"
        
        # 4. Remove the reference to the stash now that content is copied
        git stash drop $STASH_REF
        
        echo -e "$GREEN Stashed contents successfully saved to '$STASH_EXTRACT_DIR/' $NC"
    fi
fi


# 5. Pull the latest code from the 'release' branch
echo -e "$BLUE Pulling latest code from git... $NC"
git pull origin release
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to pull updates. Aborting. $NC"
  popd
  exit 1
fi



# 7. Run the build process (Crucial step 2)
# This command compiles your source code into the static 'build' directory that PM2 serves.
echo -e "$BLUE Running production build (npm run build)... $NC"
npm run build
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to run production build. Aborting. $NC"
  popd
  exit 1
fi

# 8. Restart the specific PM2 service
echo -e "$GREEN Restarting droneengage-web via PM2... $NC"
sudo pm2 restart droneengage-web

# 9. Return to the original directory
popd

echo -e "$GREEN DroneEngage web client update complete! $NC"
