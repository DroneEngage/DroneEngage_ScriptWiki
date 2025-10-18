#!/bin/bash

echo "Network may disconnect - wait for 2 min and check for AccessPoint in Wifi List."
# Stop and disable dnsmasq and hostapd services to avoid conflicts
# Use '|| true' and '2>/dev/null' to prevent errors if services don't exist
sudo systemctl stop dnsmasq 2>/dev/null || true
sudo systemctl disable dnsmasq 2>/dev/null || true
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl disable hostapd 2>/dev/null || true


# Delete existing hotspot connection if it exists
sudo nmcli con delete hotspot

# Create a new Wi-Fi AP connection
sudo nmcli con add type wifi ifname wlan0 con-name hotspot ssid "DE_ADMIN" autoconnect yes
sudo nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
sudo nmcli con modify hotspot wifi-sec.psk "droneengage"
sudo nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg
sudo nmcli con modify hotspot wifi-sec.proto rsn  # Explicitly use WPA2 (RSN)
sudo nmcli con modify hotspot wifi-sec.pairwise ccmp  # Use CCMP (AES) encryption
sudo nmcli con modify hotspot wifi-sec.group ccmp
sudo nmcli con modify hotspot ipv4.method shared ipv4.addresses 192.169.9.1/24
sudo nmcli con modify hotspot ipv6.method ignore
sudo nmcli con modify hotspot 802-11-wireless-security.wps disabled

# Bring up the hotspot
sudo nmcli con up hotspot