#!/bin/bash

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Script to stop specific services

log_warn "Stopping Drone Camera RPI services..."

# Stop de_camera_rpi_cam.service
log_info "Stopping de_camera_rpi_cam.service..."
if sudo systemctl stop de_camera_rpi_cam.service; then
  log_info "de_camera_rpi_cam.service stopped successfully."
else
  log_error "Failed to stop de_camera_rpi_cam.service."
fi

#User Info
log_warn "This script stops the following services:"
log_info " - de_camera_rpi_cam.service"
log_warn "These services are related to the Drone Engine system."
log_warn "You will be prompted for your sudo password to execute these commands."
log_warn "Please ensure you have the necessary permissions to stop these services."