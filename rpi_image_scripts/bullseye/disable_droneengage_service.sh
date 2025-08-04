#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to disable specific services

echo -e "${YELLOW}Disabling Drone Engine services...${NC}"

# Disable de_communicator.service
echo -e "${BLUE}Disabling de_communicator.service...${NC}"
if sudo systemctl disable de_communicator.service; then
  echo -e "${GREEN}de_communicator.service disabled successfully.${NC}"
else
  echo -e "${RED}Failed to disable de_communicator.service.${NC}"
fi

# Disable de_mavlink.service
echo -e "${BLUE}Disabling de_mavlink.service...${NC}"
if sudo systemctl disable de_mavlink.service; then
  echo -e "${GREEN}de_mavlink.service disabled successfully.${NC}"
else
  echo -e "${RED}Failed to disable de_mavlink.service.${NC}"
fi

# Disable de_camera.service
echo -e "${BLUE}Disabling de_camera.service...${NC}"
if sudo systemctl disable de_camera.service; then
  echo -e "${GREEN}de_camera.service disabled successfully.${NC}"
else
  echo -e "${RED}Failed to disable de_camera.service.${NC}"
fi

echo -e "${GREEN}All Drone Engine services disabled.${NC}"

#User Info
echo -e "${YELLOW}This script disables the following services:${NC}"
echo -e "${BLUE} - de_communicator.service${NC}"
echo -e "${BLUE} - de_mavlink.service${NC}"
echo -e "${BLUE} - de_camera.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to disable these services.${NC}"

#Stop the services that are already running.
echo -e "${YELLOW}Stopping services that are currently running...${NC}"

# Stop de_communicator.service
echo -e "${BLUE}Stopping de_communicator.service...${NC}"
if sudo systemctl stop de_communicator.service; then
  echo -e "${GREEN}de_communicator.service stopped successfully.${NC}"
else
  echo -e "${RED}Failed to stop de_communicator.service.${NC}"
fi

# Stop de_mavlink.service
echo -e "${BLUE}Stopping de_mavlink.service...${NC}"
if sudo systemctl stop de_mavlink.service; then
  echo -e "${GREEN}de_mavlink.service stopped successfully.${NC}"
else
  echo -e "${RED}Failed to stop de_mavlink.service.${NC}"
fi

# Stop de_camera.service
echo -e "${BLUE}Stopping de_camera.service...${NC}"
if sudo systemctl stop de_camera.service; then
  echo -e "${GREEN}de_camera.service stopped successfully.${NC}"
else
  echo -e "${RED}Failed to stop de_camera.service.${NC}"
fi

echo -e "${GREEN}All Drone Engine services that were running are now stopped.${NC}"
