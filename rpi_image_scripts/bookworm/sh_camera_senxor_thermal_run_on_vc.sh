#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

CAM_LABEL_PREFIX="DE-THERMAL"
TARGET_CAM_NAME="$CAM_LABEL_PREFIX"

echo -e "${YELLOW}Searching for virtual camera: ${TARGET_CAM_NAME}${NC}"

# Iterate through all video4linux devices in sysfs
# This is more reliable than direct /dev/videoX guesses
for video_dir in /sys/devices/virtual/video4linux/video*; do
    if [ -d "$video_dir" ]; then
        current_card_label=""
        # Try to read 'name' file first (more common on recent kernels for v4l2loopback)
        if [ -f "$video_dir/name" ]; then
            current_card_label=$(cat "$video_dir/name")
        # Fallback to 'card' file for older kernels
        elif [ -f "$video_dir/card" ]; then
            current_card_label=$(cat "$video_dir/card")
        fi

        # Debugging: Uncomment the line below to see all device labels being checked
        # echo "Checking device $(basename "$video_dir") with label: '${current_card_label}'"

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
    echo -e "${YELLOW}Please ensure 'v4l2loopback' is loaded with this card_label.${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${TARGET_CAM_NAME} at ${TARGET_DEVICE}. Starting video pipeline...${NC}"

# Build the command to match the provided pipeline
COMMAND="/bin/bash -c \"/home/pi/senxor_venv/bin/python /opt/thermal_app/thermal_toolbox.py --stream | ffmpeg -f rawvideo -pixel_format rgb24 -video_size 640x480 -framerate 5 -i - -f v4l2 ${TARGET_DEVICE}\""

echo -e "${BLUE}Executing command: ${YELLOW}${COMMAND}${NC}"

eval ${COMMAND}