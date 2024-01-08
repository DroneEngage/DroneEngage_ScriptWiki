#!/bin/bash

# Update the package lists
sudo apt-get update




###################################### NODEJS 

if command -v node &>/dev/null; then
  echo -e "${GREEN}Node.js is already installed. Skipping installation.${NC}"
else
  echo -e $GREEN "Install NodeJS" $NC
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sudo npm install -g npm@latest
fi
node -v
npm -v

read -p "Press any key to proceed " k

###################################### PM2
 

# Check if pm2 is already installed
if npm list -g pm2 &>/dev/null; then
  echo "pm2 is already installed. Skipping installation."
  pm2 --version
else
  # Install pm2 globally
  echo -e $GREEN "Install PM2" $NC
  sudo npm install -g pm2 -timeout=9999999
  sudo pm2 startup
  sudo pm2 save
fi
pm2 -v

###################################### NODE-HTTP-SERVER
echo -e $GREEN "Install Http-Server" $NC
sudo npm install http-server -g -timeout=9999999

###################################### Local HTTP-Server

echo -e $GREEN "Install Local HTTP-Server" $NC


mkdir -p ~/drone_engage/de_sonar/sonar_logs
pushd  ~/drone_engage/de_sonar/sonar_logs
echo -e $YELLOW "Put cached IMAGES at ${PWD}" $NC
sudo pm2 startup
sudo pm2 start http-server  -n map_server -x  -- ~/drone_engage/de_sonar/sonar_logs  -p 88 
sudo pm2 save
sudo pm2 list
popd
read -p "Press any key to proceed " k


###################################### Install dependencies
sudo apt-get install hostapd dnsmasq -y

# Stop the services before modifying their configuration
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq


# Configure a static IP address for the AP interface (e.g., wlan0)
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
echo "interface wlan0" | sudo tee -a /etc/dhcpcd.conf
echo "static ip_address=192.168.4.1/24" | sudo tee -a /etc/dhcpcd.conf
echo "nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf

# Configure the DHCP server (dnsmasq)
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
echo "interface=wlan0" | sudo tee -a /etc/dnsmasq.conf
echo "dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" | sudo tee -a /etc/dnsmasq.conf


# Prompt the user to enter the network SSID
read -p "Enter the network SSID: " ssid

# Prompt the user to enter the network password
read -p "Enter the network password: " password

# Configure the access point (hostapd)
echo "country_code=US" | sudo tee /etc/hostapd/hostapd.conf
echo "interface=wlan0" | sudo tee -a /etc/hostapd/hostapd.conf
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

# Enable NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Configure iptables to load the rules at startup
echo "iptables-restore < /etc/iptables.ipv4.nat" | sudo tee -a /etc/rc.local

# Start the services
sudo systemctl start hostapd
sudo systemctl start dnsmasq

sudo systemctl unmask hostapd.service

# Enable the services to start on boot
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

echo "Host AP setup complete."