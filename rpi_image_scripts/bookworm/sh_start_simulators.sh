#!/bin/bash

/home/pi/scripts/sh_stop_simulators.sh 

# Define color codes for consistent console output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Log message function for consistent colored output
log_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}



# Change to home directory for consistent working directory
log_message "${BLUE}" "Changing to home directory (~)..."
cd ~ || { log_message "${RED}" "Failed to change to home directory"; exit 1; }
log_message "${GREEN}" "Changed to $(pwd)"


# Delete old logs and terrain, continue on failure
log_message "${BLUE}" "Deleting old logs and terrain directories..."
sudo rm -rf ~/logs || { log_message "${YELLOW}" "Warning: Failed to delete ~/logs, continuing..."; }
sudo rm -rf ~/terrain || { log_message "${YELLOW}" "Warning: Failed to delete ~/terrain, continuing..."; }
log_message "${GREEN}" "Deletion attempt completed"


# Create temporary directory for SITL parameter file
log_message "${BLUE}" "Creating temporary directory for SITL parameter file..."
TEMP_DIR=$(mktemp -d) || { log_message "${RED}" "Failed to create temporary directory"; exit 1; }
log_message "${GREEN}" "Created temporary directory: $TEMP_DIR"


log_message "${GREEN}" "SITL initialization wait complete"

# Start DroneEngage de_comm and de_mavlink instances
log_message "${BLUE}" "Starting de_comm instance 1..."
/home/pi/drone_engage/de_comm/de_comm \
    --config /home/pi/simulator/sim_de_mavlink_instances/de_comm.1.config.module.json \
    --bconfig /home/pi/simulator/sim_de_mavlink_instances/de_comm.1.config.module.bconfig.local > /dev/null 2>&1 &
DE_COMM_PID1=$!
log_message "${GREEN}" "de_comm instance 1 started (PID: $DE_COMM_PID1)"

log_message "${BLUE}" "Starting de_mavlink instance 1..."
/home/pi/drone_engage/de_mavlink/de_ardupilot \
    --config /home/pi/simulator/sim_de_mavlink_instances/de_mavlink.1.config.module.json \
    --bconfig /home/pi/simulator/sim_de_mavlink_instances/de_mavlink.1.bconfig.module.local > /dev/null 2>&1 &
DE_MAVLINK_PID1=$!
log_message "${GREEN}" "de_mavlink instance 1 started (PID: $DE_MAVLINK_PID1)"

### WAIT so that Drone GENERATE Different PartyIDs
sleep 1

log_message "${BLUE}" "Starting de_comm instance 2..."
/home/pi/drone_engage/de_comm/de_comm \
    --config /home/pi/simulator/sim_de_mavlink_instances/de_comm.2.config.module.json \
    --bconfig /home/pi/simulator/sim_de_mavlink_instances/de_comm.2.config.module.bconfig.local > /dev/null 2>&1 &
DE_COMM_PID2=$!
log_message "${GREEN}" "de_comm instance 2 started (PID: $DE_COMM_PID2)"

log_message "${BLUE}" "Starting de_mavlink instance 2..."
/home/pi/drone_engage/de_mavlink/de_ardupilot \
    --config /home/pi/simulator/sim_de_mavlink_instances/de_mavlink.2.config.module.json \
    --bconfig /home/pi/simulator/sim_de_mavlink_instances/de_mavlink.2.bconfig.module.local > /dev/null 2>&1 &
DE_MAVLINK_PID2=$!
log_message "${GREEN}" "de_mavlink instance 2 started (PID: $DE_MAVLINK_PID2)"

# Staring SITL
log_message "${YELLOW}" "Waiting to start SITL"

sleep 2

# Start SITL instances in the background
log_message "${BLUE}" "Starting SITL instance 1..."
sudo /home/pi/simulator/ardupilot/build/sitl/bin/arducopter --model + --speedup 1 --sysid 1 --slave 0 \
    --defaults /home/pi/simulator/ardupilot/Tools/autotest/default_params/copter.parm \
    --sim-address 127.0.0.1 --base-port 7500   > /dev/null 2>&1 &
SITL_PID1=$!
disown $SITL_PID1
log_message "${GREEN}" "SITL instance 1 started (PID: $SITL_PID1)"

log_message "${BLUE}" "Starting SITL instance 2..."
sudo /home/pi/simulator/ardupilot/build/sitl/bin/arducopter --model + --speedup 1 --sysid 2 --slave 0 \
    --defaults /home/pi/simulator/ardupilot/Tools/autotest/default_params/copter.parm \
    --sim-address=127.0.0.1 --base-port 7600  > /dev/null 2>&1 &
SITL_PID2=$!
disown $SITL_PID2
log_message "${GREEN}" "SITL instance 2 started (PID: $SITL_PID2)"

# Wait for SITL initialization

# Display summary
log_message "${YELLOW}" "All Processes are running."

# Exit successfully
exit 0