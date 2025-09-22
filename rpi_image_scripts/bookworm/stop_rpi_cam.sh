#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to stop specific services

echo -e "${YELLOW}Stopping Drone Camera RPI services...${NC}"


# Stop de_camera_rpi_cam.service
echo -e "${BLUE}Stopping de_camera_rpi_cam.service...${NC}"
if sudo systemctl stop de_camera_rpi_cam.service; then
  echo -e "${GREEN}de_camera_rpi_cam.service stopped successfully.${NC}"
else
  echo -e "${RED}Failed to stop de_camera_rpi_cam.service.${NC}"
fi


#User Info
echo -e "${YELLOW}This script stops the following services:${NC}"
echo -e "${BLUE} - de_camera_rpi_cam.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to stop these services.${NC}"