#!/bin/bash

# --- Display version for de_comm ---
echo "✅ de_comm Version:"
echo "-------------------"
/home/pi/drone_engage_binary/de_comm/de_comm -v
echo ""

# --- Display version for de_ardupilot ---
echo "✅ de_ardupilot Version:"
echo "------------------------"
/home/pi/drone_engage_binary/de_mavlink/de_ardupilot -v
echo ""


# --- Display version for de_camera ---
echo "✅ de_camera Version:"
echo "------------------------"
/home/pi/drone_engage_binary/de_camera/de_camera -v
echo ""


# --- Display version for de_sdr ---
echo "✅ de_sdr Version:"
echo "------------------"
/home/pi/drone_engage_binary/de_sdr/de_sdr -v
echo ""

# --- Display version for de_tracker ---
echo "✅ de_tracker Version:"
echo "----------------------"
/home/pi/drone_engage_binary/de_tracking/de_tracker -v
echo ""

echo "Done checking versions."

