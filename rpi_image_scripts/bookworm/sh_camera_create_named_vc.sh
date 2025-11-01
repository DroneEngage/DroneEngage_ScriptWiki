#!/bin/bash

# This script creates named virtual camera devices using v4l2loopback.
# It assumes the v4l2loopback module is either not loaded or loaded with compatible settings.

# Define color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# --- Configuration ---
NUM_DEVICES=5
VIDEO_NR="1,2,3,4,5"
CARD_LABELS="DE-CAM1,DE-CAM2,DE-TRK,DE-RPI,DE-THERMAL"
EXCLUSIVE_CAPS="1,1,1,1,1"

# Check if v4l2loopback is already loaded
if ! lsmod | grep -q v4l2loopback; then
    echo -e "${YELLOW}Loading v4l2loopback module...${NC}"
    # Attempt to load the module with specified parameters
    sudo modprobe v4l2loopback devices=${NUM_DEVICES} video_nr=${VIDEO_NR} card_label="${CARD_LABELS}" exclusive_caps=${EXCLUSIVE_CAPS}
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to load v4l2loopback module.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}v4l2loopback module is already loaded.${NC}"
fi

echo -e "${BLUE}Virtual video devices created/verified:${NC}"

#v4l2-ctl --list-devices

ls --color=always /sys/devices/virtual/video4linux/

