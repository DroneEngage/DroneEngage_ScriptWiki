#!/bin/bash

ssid="$1"
password="$2"
interface="wlan0" # Replace with your WiFi interface

if [ -z "$ssid" ] || [ -z "$password" ]; then
  echo "SSID and password are required."
  exit 1
fi

# Backup the original wpa_supplicant.conf
backup_file="/etc/wpa_supplicant/wpa_supplicant.conf.bak.$(date +%Y%m%d%H%M%S)"
sudo cp /etc/wpa_supplicant/wpa_supplicant.conf "$backup_file"

# Generate the new wpa_supplicant.conf content
new_config=$(cat <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
        ssid="$ssid"
        psk="$password"
}
EOF
)

# Write the new configuration to wpa_supplicant.conf
echo "$new_config" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null

# Reconfigure the WiFi interface
# sudo wpa_cli -i "$interface" reconfigure
sudo rm /etc/dhcpcd.conf
sudo systemctl stop hostapd.service
echo "Disable access Point : sudo systemctl stop hostapd.service"
sudo systemctl mask hostapd.service
echo "Disable access Point: sudo systemctl mask hostapd.service"
sudo systemctl restart  dhcpcd.service

if [ $? -eq 0 ]; then
  echo "WiFi configuration successful."
else
  echo "WiFi configuration failed."
  exit 1
fi

exit 0

sleep 10

sudo reboot now

