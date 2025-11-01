#!/bin/bash

# ==========================================================
# RPI Build, Compile, and Deploy Script
# Run with 'bash build_deploy.sh'
# ==========================================================

# 1. Color Definitions
# ANSI escape codes for colors and formatting
RED='\033[0;31m'    # Error/Warning
GREEN='\033[0;32m'  # Success/Complete
BLUE='\033[0;34m'   # Main Header
CYAN='\033[0;36m'   # Informational Text
BOLD='\033[1m'      # Bold Text
NC='\033[0m'        # No Color (reset formatting)

# 2. Configuration Variables (Edit these paths)
# Use full paths for safety and clarity
PROJECT_ROOT_DIR="$HOME/de_code/droneengage_visual_tracker"
DEPLOYMENT_TARGET_DIR="$HOME/drone_engage_binary/de_tracking"
BUILD_BRANCH="release"

# 3. Safety and Error Handling
# Exit immediately if any command fails. CRITICAL for automation.
set -e

echo -e "${BLUE}${BOLD}--- DRONE ENGAGE BUILD START ---${NC}"
echo -e "${CYAN}Starting build process for branch: ${BOLD}${BUILD_BRANCH}${NC}"
echo -e "${CYAN}Project Root: ${PROJECT_ROOT_DIR}${NC}"

# Navigate to the project root
pushd "$PROJECT_ROOT_DIR"

# --- Git Operations ---
echo -e "\n${BLUE}${BOLD}1. Fetching latest code...${NC}"
git checkout "$BUILD_BRANCH"
# Using a clean fetch/reset to match the remote state exactly.
git fetch upstream "$BUILD_BRANCH"
git reset --hard upstream/"$BUILD_BRANCH"

# --- Cleanup ---
echo -e "\n${BLUE}${BOLD}2. Cleaning previous build artifacts...${NC}"
# Remove only the build folder and logs folder
rm -rf ./logs
rm -rf ./build
rm -rf "$DEPLOYMENT_TARGET_DIR"

# --- CMake Build ---
echo -e "\n${BLUE}${BOLD}3. Starting clean CMake build...${NC}"
mkdir build
cd build

# Use RELEASE build type. 
cmake -D CMAKE_BUILD_TYPE=RELEASE ../
# If 'make' fails here, 'set -e' will immediately exit the script,
# preventing the copy step below from running.
make

# --- Deployment ---
echo -e "\n${BLUE}${BOLD}4. Deploying compiled binaries to ${DEPLOYMENT_TARGET_DIR}...${NC}"

# Ensure the deployment directory exists before copying
mkdir -p "$DEPLOYMENT_TARGET_DIR"

# Copy all executables/libraries from the bin folder to the target directory
cp "$PROJECT_ROOT_DIR"/bin/* "$DEPLOYMENT_TARGET_DIR/"

# Return to the original directory
popd

"$DEPLOYMENT_TARGET_DIR"/de_tracker

echo -e "\n${GREEN}${BOLD}✅ BUILD AND DEPLOYMENT SUCCESSFUL!${NC}"
