#!/bin/bash

# Check if /etc/os-release exists
if [ -f /etc/os-release ]; then
  # Check if VERSION_CODENAME is "bullseye"
  if grep -q "VERSION_CODENAME=bullseye" /etc/os-release; then
    echo "This is Raspberry Pi OS Bullseye."
    exit 0 # Success
  else
    echo "This is not Raspberry Pi OS Bullseye."
    exit 1 # Failure
  fi
else
  echo "/etc/os-release not found."
  exit 1 # Failure
fi

