#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to enable and start specific services

echo -e "${YELLOW}Enabling and starting RPI Camera services...${NC}"

# Enable and start de_camera_rpi_cam.service
echo -e "${BLUE}Enabling and starting de_camera_rpi_cam.service...${NC}"
if sudo systemctl unmask de_camera_rpi_cam.service && sudo systemctl enable de_camera_rpi_cam.service && sudo systemctl start de_camera_rpi_cam.service; then
  echo -e "${GREEN}de_camera_rpi_cam.service enabled and started successfully.${NC}"
else
  echo -e "${RED}Failed to enable and start de_camera_rpi_cam.service.${NC}"
fi

echo -e "${GREEN}DE RPI Camera Capture services enabled and started.${NC}"

#User Info
echo -e "${YELLOW}This script enables and starts the following services:${NC}"
echo -e "${BLUE} - de_camera_rpi_cam.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to enable and start these services.${NC}"

