sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq
sudo systemctl stop hostapd
sudo systemctl disable hostapd
# sudo apt remove dnsmasq hostapd # Only if you are sure you don't need them for other purposes

# sudo systemctl status NetworkManager

sudo nmcli con delete hotspot # Remove if it exists to start fresh
sudo nmcli con add type wifi ifname wlan0 con-name hotspot ssid "DE_ADMIN" autoconnect yes
sudo nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
sudo nmcli con modify hotspot wifi-sec.psk "droneengage"
sudo nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
sudo nmcli con modify hotspot ipv4.method shared ipv4.addresses 192.169.9.1/24
sudo nmcli con up hotspot

#sudo nmcli con show hotspot
#sudo nmcli device wifi list # See if your hotspot is broadcast
#sudo nmcli device show wlan0 # Check IP, etc.
#journalctl -u NetworkManager -f # Watch logs for errors


