#!/bin/bash

# Color definitions for terminal output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Script to stop specific services

echo -e "${YELLOW}Stopping Drone Engine services...${NC}"

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


echo -e "${GREEN}All Drone Engine services stopped.${NC}"

#User Info
echo -e "${YELLOW}This script stops the following services:${NC}"
echo -e "${BLUE} - de_communicator.service${NC}"
echo -e "${BLUE} - de_mavlink.service${NC}"
echo -e "${YELLOW}These services are related to the Drone Engine system.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password to execute these commands.${NC}"
echo -e "${YELLOW}Please ensure you have the necessary permissions to stop these services.${NC}"