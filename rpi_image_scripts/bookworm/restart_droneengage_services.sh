#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to restart specific services

echo -e "${YELLOW}Restarting Drone Engine services...${NC}"

# Restart de_communicator.service
echo -e "${BLUE}Restarting de_communicator.service...${NC}"
if sudo systemctl restart de_communicator.service; then
  echo -e "${GREEN}de_communicator.service restarted successfully.${NC}"
else
  echo -e "${RED}Failed to restart de_communicator.service.${NC}"
fi

# Restart de_mavlink.service
echo -e "${BLUE}Restarting de_mavlink.service...${NC}"
if sudo systemctl restart de_mavlink.service; then
  echo -e "${GREEN}de_mavlink.service restarted successfully.${NC}"
else
  echo -e "${RED}Failed to restart de_mavlink.service.${NC}"
fi

# Restart de_camera.service
echo -e "${BLUE}Restarting de_camera.service...${NC}"
if sudo systemctl restart de_camera.service; then
  echo -e "${GREEN}de_camera.service restarted successfully.${NC}"
else
  echo -e "${RED}Failed to restart de_camera.service.${NC}"
fi

echo -e "${GREEN}All Drone Engine services restarted.${NC}"

#User Info
echo -e "${YELLOW}This script restarts the following services:${NC}"
echo -e "${BLUE} - de_communicator.service${NC}"
echo -e "${BLUE} - de_mavlink.service${NC}"
echo -e "${BLUE} - de_camera.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to restart these services.${NC}"