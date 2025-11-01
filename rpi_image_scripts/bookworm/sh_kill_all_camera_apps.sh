#!/bin/bash

# Define color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo "Killing Camera Apps"

echo -e "${RED}KILLING Camera Related APPs.${NC}"

# Use '--signal 9' or '-s 9' to specify the kill signal
sudo pkill --signal 9 -f rpicam-vid
sudo pkill --signal 9 -f de_tracker.so
sudo pkill --signal 9 -f de_ai_tracker.so
sudo pkill --signal 9 -f de_camera

# fix screen
stty sane
