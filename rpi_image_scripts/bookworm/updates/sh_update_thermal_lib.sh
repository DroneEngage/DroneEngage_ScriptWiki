#!/bin/bash

# ANSI Color Definitions
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m' # No Color (Reset)

echo -e "${BLUE}Updating Thermal Camera Lib...${NC}"
rm -rf /home/pi/senxor_venv
python3 -m venv /home/pi/senxor_venv
source /home/pi/senxor_venv/bin/activate
pip install git+https://github.com/HefnySco/pysenxor-lite.git@pr_drone_engage_thermal_camera
deactivate

