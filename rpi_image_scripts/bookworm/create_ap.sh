#!/bin/bash
# BOOKWORM CODE
SSID_IP='192.189.9.1'

DOMAIN_NAME='airgap.droneengage.com'

# Update package lists
sudo apt-get update

# Install dependencies
sudo apt-get install hostapd dnsmasq -y

# Get Router IP (x.x.x.x -> x.x.x.)
IP_NETWORK=$(echo "$SSID_IP" | cut -d'.' -f1-3)
echo "IP_NETWORK: $IP_NETWORK"

# Check wireless interface
INTERFACE=$(iwconfig | grep -oP '^[^ ]+' | head -n 1)
if [[ -z "$INTERFACE" ]]; then
  echo "Error: No wireless interface found.  Check your wireless adapter."
  exit 1
fi
echo "Using wireless interface: $INTERFACE"

# Stop services
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Configure static IP
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
echo "interface $INTERFACE" | sudo tee /etc/dhcpcd.conf  # Overwrite
echo "static ip_address=$SSID_IP/24" | sudo tee -a /etc/dhcpcd.conf
echo "nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf

# Configure dnsmasq
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
echo "interface=$INTERFACE" | sudo tee /etc/dnsmasq.conf  # Overwrite
echo "dhcp-range=$IP_NETWORK.2,$IP_NETWORK.120,255.255.255.0,24h" | sudo tee -a /etc/dnsmasq.conf
# Add the redirection rule
echo "address=/$DOMAIN_NAME/$SSID_IP" | sudo tee -a /etc/dnsmasq.conf  # Redirect to AP IP

# Get SSID and password
read -p "Enter the network SSID: " ssid
read -p "Enter the network password: " password

# Configure hostapd
echo "country_code=US" | sudo tee /etc/hostapd/hostapd.conf  # Overwrite
echo "interface=$INTERFACE" | sudo tee -a /etc/hostapd/hostapd.conf
echo "ssid=$ssid" | sudo tee -a /etc/hostapd/hostapd.conf
echo "hw_mode=g" | sudo tee -a /etc/hostapd/hostapd.conf
echo "channel=7" | sudo tee -a /etc/hostapd/hostapd.conf
echo "macaddr_acl=0" | sudo tee -a /etc/hostapd/hostapd.conf
echo "auth_algs=1" | sudo tee -a /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0" | sudo tee -a /etc/hostapd/hostapd.conf
echo "wpa=2" | sudo tee -a /etc/hostapd/hostapd.conf
echo "wpa_passphrase=$password" | sudo tee -a /etc/hostapd/hostapd.conf
echo "wpa_key_mgmt=WPA-PSK" | sudo tee -a /etc/hostapd/hostapd.conf
echo "wpa_pairwise=TKIP" | sudo tee -a /etc/hostapd/hostapd.conf
echo "rsn_pairwise=CCMP" | sudo tee -a /etc/hostapd/hostapd.conf

# Enable IPv4 forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Enable NAT (using systemd service)
cat <<EOF | sudo tee /etc/systemd/system/iptables-nat.service
[Unit]
Description=iptables NAT rules
After=network-online.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore < /etc/iptables.ipv4.nat
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo systemctl enable iptables-nat.service


# Start services
sudo systemctl start hostapd
sudo systemctl start dnsmasq

sudo systemctl unmask hostapd.service  # Uncomment if needed

# Enable on boot
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

echo "Host AP setup complete."
read -p "Press any key to reboot now " k
sudo reboot now

