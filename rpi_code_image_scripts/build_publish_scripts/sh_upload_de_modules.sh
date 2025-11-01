#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

usage() {
  echo -e "${BOLD}Usage:${RESET} $0 [--help]";
  echo;
  echo -e "${BLUE}Uploads${RESET} release artifacts from ${BOLD}/home/pi/drone_engage_output/releases${RESET} to a remote server via scp.";
  echo -e "Transfers: ${BOLD}*.tar.gz${RESET}, ${BOLD}*.sha256${RESET}, and ${BOLD}*_LATEST${RESET}.";
  echo;
  echo -e "${BOLD}Current config (edit in script):${RESET}";
  echo -e "  SRC_DIR=\"${YELLOW}$SRC_DIR${RESET}\"";
  echo -e "  DEST_USER=\"${YELLOW}$DEST_USER${RESET}\"";
  echo -e "  DEST_HOST=\"${YELLOW}$DEST_HOST${RESET}\"";
  echo -e "  DEST_PATH=\"${YELLOW}$DEST_PATH${RESET}\"";
  echo -e "  PORT=${YELLOW}$PORT${RESET}";
}

# Show help and exit
if [[ ${1-} == "--help" ]]; then
  # Initialize defaults shown in usage without executing the rest
  SRC_DIR="/home/pi/drone_engage_output/releases"
  DEST_USER="root"
  DEST_HOST="cloud.ardupilot.org"
  DEST_PATH="/home/ap_cloud/binaries_download/RPI/Latest/"
  PORT=22
  usage
  exit 0
fi

SRC_DIR="/home/pi/drone_engage_output/releases"
DEST_USER="root"
DEST_HOST="cloud.ardupilot.org"
DEST_PATH="/home/ap_cloud/binaries_download/RPI/Latest/"
PORT=22

# Ensure destination exists
ssh -i /home/pi/.ssh/id_rsa -p "$PORT" "${DEST_USER}@${DEST_HOST}" "mkdir -p '$DEST_PATH'"

# Enable nullglob so unmatched globs vanish rather than upload literals
shopt -s nullglob

files=( "$SRC_DIR"/*.tar.gz "$SRC_DIR"/*.sha256 "$SRC_DIR"/*_LATEST )
if ((${#files[@]} == 0)); then
  echo -e "${YELLOW}No files to upload in $SRC_DIR${RESET}"
  exit 0
fi

scp -i /home/pi/.ssh/id_rsa -P "$PORT" "${files[@]}" "${DEST_USER}@${DEST_HOST}":"$DEST_PATH"/
echo -e "${GREEN}Uploaded successfully.${RESET}"