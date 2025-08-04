#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to enable and start specific services

echo -e "${YELLOW}Enabling and starting Drone Engine services...${NC}"

# Enable and start de_communicator.service
echo -e "${BLUE}Enabling and starting de_communicator.service...${NC}"
if sudo systemctl unmask de_communicator.service && sudo systemctl enable de_communicator.service && sudo systemctl start de_communicator.service; then
  echo -e "${GREEN}de_communicator.service enabled and started successfully.${NC}"
else
  echo -e "${RED}Failed to enable and start de_communicator.service.${NC}"
fi

# Enable and start de_mavlink.service
echo -e "${BLUE}Enabling and starting de_mavlink.service...${NC}"
if sudo systemctl unmask de_mavlink.service && sudo systemctl enable de_mavlink.service && sudo systemctl start de_mavlink.service; then
  echo -e "${GREEN}de_mavlink.service enabled and started successfully.${NC}"
else
  echo -e "${RED}Failed to enable and start de_mavlink.service.${NC}"
fi

# Enable and start de_camera.service
echo -e "${BLUE}Enabling and starting de_camera.service...${NC}"
if sudo systemctl unmask de_camera.service && sudo systemctl enable de_camera.service && sudo systemctl start de_camera.service; then
  echo -e "${GREEN}de_camera.service enabled and started successfully.${NC}"
else
  echo -e "${RED}Failed to enable and start de_camera.service.${NC}"
fi

echo -e "${GREEN}All Drone Engine services enabled and started.${NC}"

#User Info
echo -e "${YELLOW}This script enables and starts the following services:${NC}"
echo -e "${BLUE} - de_communicator.service${NC}"
echo -e "${BLUE} - de_mavlink.service${NC}"
echo -e "${BLUE} - de_camera.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to enable and start these services.${NC}"

