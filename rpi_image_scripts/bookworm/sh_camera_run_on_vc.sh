#!/bin/bash

# Script: sh_run_virtual_camera.sh
# Usage: sh_run_virtual_camera.sh <camera_index> [postprocess_file_path]
# Example:
#   sh_run_virtual_camera.sh 2                         (to stream to the 2nd virtual camera without post-processing)
#   sh_run_virtual_camera.sh 2 "/path/to/my/model.json" (to stream to the 2nd virtual camera with a specific post-processing file)
#
# This script identifies the virtual camera by its card_label (DE-CAM1, DE-CAM2, etc.)
# based on the provided index, and then starts a GStreamer pipeline to it.
#
# Prerequisites:
# - v4l2loopback module loaded with appropriate card_label options (e.g., DE-CAM1, DE-CAM2, DE-CAM3)
#   Example: sudo modprobe v4l2loopback devices=3 video_nr=1,2,3 card_label="DE-CAM1,DE-CAM2,DE-CAM3" exclusive_caps=1,1,1
# - GStreamer and libcamera plugins installed (gstreamer1.0-tools gstreamer1.0-libcamera etc.)


# --- Configuration ---
# Define the base name for your virtual cameras.
# The script will look for "DE-CAM1", "DE-CAM2", etc.
CAM_LABEL_PREFIX="DE-CAM"

# GStreamer pipeline parameters
VIDEO_WIDTH=640
VIDEO_HEIGHT=480
VIDEO_FRAMERATE=30
VIDEO_FORMAT="YUY2" # Common format for V4L2loopback


# --- Script Logic ---

# Check for correct number of arguments
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <camera_index> [postprocess_file_path]"
    echo "Example: $0 1 (for DE-CAM1 without post-processing)"
    echo "Example: $0 2 \"/usr/share/rpi-camera-assets/imx500_mobilenet_ssd.json\" (for DE-CAM2 with post-processing)"
    exit 1
fi

CAMERA_INDEX=$1
TARGET_CAM_NAME="${CAM_LABEL_PREFIX}${CAMERA_INDEX}"
TARGET_DEVICE=""

# Assign POSTPROCESS_FILE from the second argument if provided, otherwise leave empty
POSTPROCESS_FILE="${2:-}" # This sets POSTPROCESS_FILE to the second argument, or empty if not provided.

echo "Searching for virtual camera: ${TARGET_CAM_NAME}"

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
    echo "Error: Virtual camera '${TARGET_CAM_NAME}' not found."
    echo "Please ensure 'v4l2loopback' is loaded with this card_label."
    exit 1
fi

echo "Found ${TARGET_CAM_NAME} at ${TARGET_DEVICE}. Starting GStreamer pipeline..."

# Build the rpicam-vid command with or without the post-processing file
RPICAM_VID_COMMAND="rpicam-vid -t 0 --vflip=1 --width ${VIDEO_WIDTH} --height ${VIDEO_HEIGHT} --framerate ${VIDEO_FRAMERATE} --codec yuv420 --info-text \"\""

if [ -n "$POSTPROCESS_FILE" ]; then
    RPICAM_VID_COMMAND="${RPICAM_VID_COMMAND} --post-process-file ${POSTPROCESS_FILE}"
    echo "Using post-processing file: ${POSTPROCESS_FILE}"
else
    echo "No post-processing file specified."
fi

# Construct the full FFmpeg command
FFMPG_COMMAND="${RPICAM_VID_COMMAND} -o -  | ffmpeg -f rawvideo -pixel_format yuv420p -video_size ${VIDEO_WIDTH}x${VIDEO_HEIGHT} -i - -f v4l2 -pixel_format yuv420p ${TARGET_DEVICE} -loglevel quiet"

echo "Running command: ${GST_COMMAND}"
echo "Executing command: $FFMPG_COMMAND"
eval ${FFMPG_COMMAND}


# Note: The FFmpeg command will run in the foreground until interrupted (Ctrl+C).
# If you want it to run in the background, you could add '&' at the end of the eval line,
# but usually for a streaming task, you want to see its output and manage it.
