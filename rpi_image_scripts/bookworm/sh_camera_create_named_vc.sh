#!/bin/bash

# This script creates named virtual camera devices using v4l2loopback.
# It assumes the v4l2loopback module is either not loaded or loaded with compatible settings.

# --- Configuration ---
NUM_DEVICES=3
VIDEO_NR="1,2,3"
CARD_LABELS="DE-CAM1,DE-CAM2,DE-CAM3"
EXCLUSIVE_CAPS="1,1,1"

# Check if v4l2loopback is already loaded
if ! lsmod | grep -q v4l2loopback; then
    echo "Loading v4l2loopback module..."
    # Attempt to load the module with specified parameters
    sudo modprobe v4l2loopback devices=${NUM_DEVICES} video_nr=${VIDEO_NR} card_label="${CARD_LABELS}" exclusive_caps=${EXCLUSIVE_CAPS}
    if [ $? -ne 0 ]; then
        echo "Error: Failed to load v4l2loopback module."
        exit 1
    fi
else
    echo "v4l2loopback module is already loaded."
    # Optional: You could add logic here to check if the existing module
    # parameters (like card_labels) are correct, but for now, we'll assume they are.
fi

echo "Virtual video devices created/verified:"
ls /sys/devices/virtual/video4linux/