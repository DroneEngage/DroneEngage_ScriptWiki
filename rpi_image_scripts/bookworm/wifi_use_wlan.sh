#!/bin/bash

# Check if both SSID and Password are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <SSID> <Password>"
    echo "Example: $0 MyHomeWiFi MySuperSecurePass123"
    exit 1
fi

SSID="$1"
PASSWORD="$2"
CONNECTION_NAME="Wifi_$(echo "$SSID" | tr -cd '[:alnum:]')_Conn" # Generate a simple connection name from SSID

echo "Attempting to connect to Wi-Fi network:"
echo "SSID: $SSID"
echo "Connection Name: $CONNECTION_NAME"
echo ""

# --- 1. Revert any potential hotspot configurations (safe to run always) ---
echo "1. Reverting potential hotspot configurations..."
sudo nmcli con down hotspot &>/dev/null # Try to bring it down, suppress error if not found
sudo nmcli con delete hotspot &>/dev/null # Delete it, suppress error if not found

# Ensure wlan0 is available for normal connections
echo "2. Resetting wlan0 device state..."
sudo nmcli device disconnect wlan0 &>/dev/null
sudo nmcli device set wlan0 managed yes

# --- 2. Remove existing connection with the same generated name (if any) ---
if sudo nmcli con show "$CONNECTION_NAME" &>/dev/null; then
    echo "3. Existing connection profile '$CONNECTION_NAME' found. Deleting it..."
    sudo nmcli con delete "$CONNECTION_NAME"
fi

# --- 3. Scan for Wi-Fi networks ---
echo "4. Scanning for Wi-Fi networks..."
sudo nmcli device wifi rescan
sleep 3 # Give it a moment to rescan

# --- 4. Add the new Wi-Fi connection ---
echo "5. Adding new Wi-Fi connection profile for '$SSID'..."
sudo nmcli dev wifi connect "$SSID" password "$PASSWORD" ifname wlan0 name "$CONNECTION_NAME" || {
  sudo nmcli con add type wifi ifname wlan0 con-name "$CONNECTION_NAME" ssid "$SSID" autoconnect yes
  sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.key-mgmt wpa-psk
  sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.psk "$PASSWORD"
  sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.psk-flags 0
  sudo nmcli con modify "$CONNECTION_NAME" ipv4.method auto ipv6.method auto
}

# --- 5. Activate the new connection ---
echo "6. Activating connection '$CONNECTION_NAME'..."
sudo nmcli con up "$CONNECTION_NAME"

# --- 6. Verify Connection Status ---
echo ""
echo "7. Verifying connection status..."
echo "NetworkManager device status for wlan0:"
sudo nmcli device show wlan0 | grep -E 'STATE|IP4.ADDRESS|IP4.GATEWAY'

echo "Active NetworkManager connections:"
sudo nmcli con show --active

echo "Testing internet connectivity (ping google.com):"
if ping -c 4 google.com &>/dev/null; then
    echo "Internet connection SUCCESSFUL!"
else
    echo "Internet connection FAILED. Please check logs for errors."
fi

echo ""
echo "Script finished. Check the output for connection details."

