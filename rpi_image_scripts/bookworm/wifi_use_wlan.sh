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

# --- 4. Add and connect to the Wi-Fi network ---
echo "5. Connecting to Wi-Fi network '$SSID'..."
CONNECT_SUCCESS=false

# Try direct connect first (this both creates and activates the connection)
if sudo nmcli dev wifi connect "$SSID" password "$PASSWORD" ifname wlan0 name "$CONNECTION_NAME"; then
    echo "   Direct connection successful."
    CONNECT_SUCCESS=true
else
    echo "   Direct connect failed, trying manual profile creation..."
    # Create connection profile manually
    sudo nmcli con add type wifi ifname wlan0 con-name "$CONNECTION_NAME" ssid "$SSID" autoconnect yes
    sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.key-mgmt wpa-psk
    sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.psk "$PASSWORD"
    sudo nmcli con modify "$CONNECTION_NAME" 802-11-wireless-security.psk-flags 0
    sudo nmcli con modify "$CONNECTION_NAME" ipv4.method auto ipv6.method auto
    
    # Now activate the manually created connection
    echo "6. Activating connection '$CONNECTION_NAME'..."
    if sudo nmcli con up "$CONNECTION_NAME"; then
        CONNECT_SUCCESS=true
    fi
fi

if [ "$CONNECT_SUCCESS" = false ]; then
    echo "ERROR: Failed to connect to '$SSID'."
    echo "Check SSID and password are correct."
    exit 1
fi

# --- 6. Wait for IP address assignment ---
echo ""
echo "7. Waiting for IP address assignment..."
MAX_WAIT=30
WAIT_INTERVAL=2
ELAPSED=0
IP_ADDR=""

while [ $ELAPSED -lt $MAX_WAIT ]; do
    IP_ADDR=$(sudo nmcli -g IP4.ADDRESS device show wlan0 2>/dev/null | head -n1)
    if [ -n "$IP_ADDR" ]; then
        echo "IP address obtained: $IP_ADDR"
        break
    fi
    echo "  Waiting for IP... ($ELAPSED/$MAX_WAIT seconds)"
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

if [ -z "$IP_ADDR" ]; then
    echo "WARNING: No IP address obtained after ${MAX_WAIT} seconds."
    echo "Attempting to restart DHCP..."
    sudo nmcli con down "$CONNECTION_NAME" &>/dev/null
    sleep 2
    sudo nmcli con up "$CONNECTION_NAME"
    sleep 5
    IP_ADDR=$(sudo nmcli -g IP4.ADDRESS device show wlan0 2>/dev/null | head -n1)
    if [ -z "$IP_ADDR" ]; then
        echo "ERROR: Still no IP address. Connection may be established but DHCP failed."
        echo "Check router DHCP settings or try a static IP configuration."
    else
        echo "IP address obtained after retry: $IP_ADDR"
    fi
fi

# --- 7. Verify Connection Status ---
echo ""
echo "8. Verifying connection status..."
echo "NetworkManager device status for wlan0:"
sudo nmcli device show wlan0 | grep -E 'STATE|IP4.ADDRESS|IP4.GATEWAY'

echo ""
echo "Active NetworkManager connections:"
sudo nmcli con show --active

echo ""
echo "Testing internet connectivity via wlan0..."
# Get wlan0 gateway to determine source interface
WLAN_GW=$(sudo nmcli -g IP4.GATEWAY device show wlan0 2>/dev/null)

if [ -n "$IP_ADDR" ] && [ -n "$WLAN_GW" ]; then
    # Test connectivity specifically through wlan0 interface
    if ping -c 2 -I wlan0 8.8.8.8 &>/dev/null; then
        echo "Network connectivity via wlan0: OK (can reach 8.8.8.8)"
        # Then test DNS resolution
        if ping -c 2 -I wlan0 google.com &>/dev/null; then
            echo "DNS resolution: OK"
            echo "Wi-Fi internet connection SUCCESSFUL!"
        else
            echo "DNS resolution: FAILED (network works but DNS may be misconfigured)"
        fi
    else
        echo "Network connectivity via wlan0: FAILED (have IP $IP_ADDR but cannot reach internet)"
        echo "Gateway: $WLAN_GW - Check router configuration."
    fi
else
    if [ -z "$IP_ADDR" ]; then
        echo "Network connectivity: FAILED (no IP address assigned to wlan0)"
    else
        echo "Network connectivity: FAILED (no gateway assigned to wlan0)"
    fi
fi

echo ""
echo "Script finished. Check the output for connection details."

