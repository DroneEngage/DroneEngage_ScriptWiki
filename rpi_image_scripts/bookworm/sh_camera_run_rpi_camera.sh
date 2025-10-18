#!/bin/bash

# Script: sh_run_virtual_camera.sh
# Usage: sh_run_virtual_camera.sh [postprocess_file_path]
# Example:
#   sh_run_virtual_camera.sh "/path/to/my/model.json" (to stream to DE-RPI with a specific post-processing file)
#
# This script is modified to no longer accept <camera_index> as an argument.

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color


# --- Configuration ---
# Define the base name for your virtual cameras.
CAM_LABEL_PREFIX="DE-RPI"



RPICAM_VID="/home/pi/rpicam-apps/build/apps/rpicam-vid"
RPICAM_HELLO="/home/pi/rpicam-apps/build/apps/rpicam-hello"

# FFmpeg pipeline parameters
VIDEO_WIDTH=640
VIDEO_HEIGHT=480
VIDEO_FRAMERATE=20


# --- Script Logic ---

# Check for correct number of arguments (now 0 or 1)
if [ "$#" -gt 1 ]; then
    echo -e "${YELLOW}Usage: $0 [postprocess_file_path]${NC}"
    echo -e "${YELLOW}Example: $0 (for DE-RPI without post-processing)${NC}"
    echo -e "${YELLOW}Example: $0 \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\" (for DE-RPI with post-processing)${NC}"
    exit 1
fi


# Check for RPI camera availability using libcamera-hello
echo -e "${YELLOW}Checking for Raspberry Pi camera...${NC}"
if ! ${RPICAM_HELLO} --list-cameras | grep -qi "available cameras"; then
    echo -e "${RED}No Raspberry Pi camera detected. Skipping camera pipeline.${NC}"
    exit 3 # Exit with status 2 to indicate no RPI camera
fi
echo -e "${GREEN}Raspberry Pi camera detected. Proceeding with pipeline setup...${NC}"


# *** UPDATED: Use the hardcoded index to form the target name ***
TARGET_CAM_NAME="${CAM_LABEL_PREFIX}"
TARGET_DEVICE=""

# Assign POSTPROCESS_FILE from the first argument ($1) if provided, otherwise leave empty
POSTPROCESS_FILE="${1:-}" # The post-process file is now the first (and only optional) argument.

echo -e "${YELLOW}Searching for virtual camera: ${TARGET_CAM_NAME}${NC}"

# Iterate through all video4linux devices in sysfs
for video_dir in /sys/devices/virtual/video4linux/video*; do
    if [ -d "$video_dir" ]; then
        current_card_label=""
        # Try to read 'name' file first
        if [ -f "$video_dir/name" ]; then
            current_card_label=$(cat "$video_dir/name")
        # Fallback to 'card' file for older kernels
        elif [ -f "$video_dir/card" ]; then
            current_card_label=$(cat "$video_dir/card")
        fi

        # Check if the current device's label matches our target, ignoring leading/trailing whitespace
        if [[ "$current_card_label" =~ ^[[:space:]]*${TARGET_CAM_NAME}[[:space:]]*$ ]]; then
            DEVICE_NUMBER=$(basename "$video_dir" | sed 's/^video//')
            TARGET_DEVICE="/dev/video${DEVICE_NUMBER}"
            break # Found our target, exit loop
        fi
    fi
done

if [ -z "$TARGET_DEVICE" ]; then
    echo -e "${RED}Error: Virtual camera '${TARGET_CAM_NAME}' not found.${NC}"
    echo -e "${YELLOW}Please ensure 'v4l2loopback' is loaded with card_label=\"${TARGET_CAM_NAME},...\"${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${TARGET_CAM_NAME} at ${TARGET_DEVICE}. Starting FFmpeg pipeline...${NC}"

# Build the rpicam-vid command with or without the post-processing file
RPICAM_VID_COMMAND="${RPICAM_VID} -t 0 --vflip=1 --width ${VIDEO_WIDTH} --height ${VIDEO_HEIGHT} --framerate ${VIDEO_FRAMERATE} --codec yuv420 --info-text \"\""

if [ -n "$POSTPROCESS_FILE" ]; then
    RPICAM_VID_COMMAND="${RPICAM_VID_COMMAND} --post-process-file ${POSTPROCESS_FILE}"
    echo -e "${GREEN}Using post-processing file: ${POSTPROCESS_FILE}${NC}"
else
    echo -e "${YELLOW}No post-processing file specified.${NC}"
fi

# Construct the full FFmpeg command
FFMPG_COMMAND="${RPICAM_VID_COMMAND} -o -  | ffmpeg -f rawvideo -pixel_format yuv420p -video_size ${VIDEO_WIDTH}x${VIDEO_HEIGHT} -i - -f v4l2 -pixel_format yuv420p ${TARGET_DEVICE} -loglevel quiet"

echo "Running command: ${FFMPG_COMMAND}"
echo  -e "${BLUE}Executing command: ${YELLOW}$FFMPG_COMMAND${NC}"
eval ${FFMPG_COMMAND}