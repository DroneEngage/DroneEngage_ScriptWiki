#~/bin/bash

sudo cp /etc/dhcpcd.conf.ap /etc/dhcpcd.conf
echo "Restore /etc/dhcpcd.conf"

sudo systemctl unmask hostapd.service
sudo systemctl restart hostapd.service

echo "Access Point configuration successful."

sleep 10
sudo reboot now

