#!/bin/bash

###Air Gapped Server on Raspberry PI

SCRIPT_VERSION='2.1'

DOMAIN_NAME='airgap.droneengage.com'
IP='192.168.1.161'
MACHINE_IP='192.168.1.161'
EXTERNAL_IP='192.168.1.161'  ## same as MACHINE_IP if MACHINE_IP is real ip.
MIN_WEBRTC_PORTS=20000
MAX_WEBRTC_PORTS=40000
TURN_PWD='airgap:1234'

## NODEJS Version
NODE_MAJOR=18


REPOSITORY_AUTH='https://github.com/DroneEngage/droneenage_authenticator.git'
REPOSITORY_SERVER='https://github.com/DroneEngage/droneengage_server.git'
REPOSITORY_WEBCLIENT='https://github.com/DroneEngage/droneengage_webclient_react.git'
# OLD WEBSITE REPOSITORY_WEBCLIENT='https://github.com/DroneEngage/droneengage_webclient.git'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color



echo -e $YELLOW "INSTALLING AIRGAP SERVER FOR DRONEENGAGE" $NC
echo -e $YELLOW "For mode details: https://youtu.be/R1BedRTxuuY" $NC
echo -e $GREEN "script version $SCRIPT_VERSION"
read -p "Press any key to proceed " k



sudo apt update


###################################### GET IP of the SERVER
# Prompt the user for an IP address

while true; do
  echo -e $GREEN "You need to write the static IP of this server" $NC
  read -p "Enter an IP address of this server : " ip_address

  # Validate the IP address format
  if [[ ! $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e $YELLOW  "Invalid IP address format. Please try again." $NC
    continue
  fi

  # Confirm the entered IP address
  read -p "You entered $ip_address. Is this correct? [y/n]: " confirm
  
  # Check the user's confirmation
  if [[ $confirm =~ ^[Yy]$ ]]; then
    IP=$ip_address
    MACHINE_IP=$IP
    EXTERNAL_IP=$IP
    echo -e $GREEN "IP address confirmed: $IP" $NC
    break
  else
    echo -e $YELLOW  "IP address confirmation declined." $NC
  fi
done


###################################### DHCP
# Backup the current dhcpcd.conf
echo -e $GREEN "Setup STATIC IP" $NC
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
$INTERFACE = 'wlan0'
# Add static IP configuration to dhcpcd.conf
{
    echo ""
    echo "# Static IP configuration"
    echo "interface $INTERFACE"
    echo "static ip_address=$IP/24"  # Adjust subnet mask if necessary
    echo "static routers=192.168.1.1"  # Change to your router's IP
    echo "static domain_name_servers=8.8.8.8 8.8.4.4"  # Google DNS
} | sudo tee -a /etc/dhcpcd.conf

# Restart the dhcpcd service to apply changes
sudo systemctl restart dhcpcd

echo -e $GREEN  "Static IP address $IP has been set for interface $INTERFACE." $NC

###################################### COTURN
echo -e $GREEN "Install CoTurn" $NC
sudo apt install -y coturn

echo -e $BLUE "Run CoTurn as a Service" $NC

sudo touch /etc/turnserver.conf 
sudo bash -c "cat > /etc/turnserver.conf  <<EOL
listening-port=3478
tls-listening-port=5349
listening-ip=${MACHINE_IP}
relay-ip=${MACHINE_IP}
min-port=${MIN_WEBRTC_PORTS}
max-port=${MAX_WEBRTC_PORTS}
fingerprint
lt-cred-mech
server-name=${DOMAIN_NAME}
user=${TURN_PWD}
EOL
"



###################################### SSL 
mkdir -p ~/ssl


touch ~/ssl/fullchain.pem
cat > ~/ssl/fullchain.pem <<EOL
-----BEGIN CERTIFICATE-----
MIICNzCCAd2gAwIBAgIRAJcvjtUOW4q1YHEBwF7OvjcwCgYIKoZIzj0EAwIwNjER
MA8GA1UEChMITG9jYWwgQ0ExITAfBgNVBAMTGExvY2FsIENBIEludGVybWVkaWF0
ZSBDQTAeFw0yMjA3MjMxMjEyNTFaFw0zMDA3MTgwNDEzNTFaMCExHzAdBgNVBAMT
FmFpcmdhcC5kcm9uZWVuZ2FnZS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNC
AASnUtK+lzbP8dzEgpWwl50L8FzyJ0ZCe+OtGUc+8fW4wCqrR3oA2rD8x8yKMjK/
lv5Ae8v5mznDKSnc9twjUi4io4HgMIHdMA4GA1UdDwEB/wQEAwIHgDAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwHQYDVR0OBBYEFCRDnsVDIl9qB/cQCHUI
laBSnX9sMB8GA1UdIwQYMBaAFNyNY7GDju6RYJ8bTxfcznV5z3JPMCEGA1UdEQQa
MBiCFmFpcmdhcC5kcm9uZWVuZ2FnZS5jb20wSQYMKwYBBAGCpGTGKEABBDkwNwIB
AQQFYWRtaW4EK3AwRGJ5WG5tWmxIemNGMWRPX3hOWl9UeU02TWcxanZXT0t6Qi1i
SEM3X0UwCgYIKoZIzj0EAwIDSAAwRQIgL2mPjeL/ws9ntqM9L/kMWNIf+iYDhfpj
zTGO10gjDd8CIQDOaM0E1aAmXU2QmrIIkMQkjfh9kFI89IoOoKpphJKpEA==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIByDCCAW6gAwIBAgIQczsAHzwDIBCtf1ytd1W+BjAKBggqhkjOPQQDAjAuMREw
DwYDVQQKEwhMb2NhbCBDQTEZMBcGA1UEAxMQTG9jYWwgQ0EgUm9vdCBDQTAeFw0y
MjA3MTcxMzI5NTVaFw0zMjA3MTQxMzI5NTVaMDYxETAPBgNVBAoTCExvY2FsIENB
MSEwHwYDVQQDExhMb2NhbCBDQSBJbnRlcm1lZGlhdGUgQ0EwWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAAShC3pILdoCYvIWQG7aOa+t6iPP6zZVyUsIaVFqpKprtDOH
gogVZhgvLVsdROzDSBBNzb6NbFh+Fm9CtrXfT3Tgo2YwZDAOBgNVHQ8BAf8EBAMC
AQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU3I1jsYOO7pFgnxtPF9zO
dXnPck8wHwYDVR0jBBgwFoAUq/ulWfMgEcDFXC1lpZ2gys8NV7UwCgYIKoZIzj0E
AwIDSAAwRQIgRH1xL8why5wEyHm3Z5Np+1OXN1idyKT7qLvxboYyw44CIQC5uupq
VXzG85bfmkTIuL9fae2UBB6nMEN/adWJvmKfqA==
-----END CERTIFICATE-----
EOL

touch ~/ssl/privkey.pem
cat > ~/ssl/privkey.pem <<EOL
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIJZ30pmzQctlhI92k+FuggfovqshM5GDiQFIzAOBU8jsoAoGCCqGSM49
AwEHoUQDQgAEp1LSvpc2z/HcxIKVsJedC/Bc8idGQnvjrRlHPvH1uMAqq0d6ANqw
/MfMijIyv5b+QHvL+Zs5wykp3PbcI1IuIg==
-----END EC PRIVATE KEY-----
EOL

touch ~/ssl/root.crt
cat > ~/ssl/root.crt <<EOL
-----BEGIN CERTIFICATE-----
MIIBoDCCAUagAwIBAgIRAIRoieoJaTtMHil6bJCuTCcwCgYIKoZIzj0EAwIwLjER
MA8GA1UEChMITG9jYWwgQ0ExGTAXBgNVBAMTEExvY2FsIENBIFJvb3QgQ0EwHhcN
MjIwNzE3MTMyOTU0WhcNMzIwNzE0MTMyOTU0WjAuMREwDwYDVQQKEwhMb2NhbCBD
QTEZMBcGA1UEAxMQTG9jYWwgQ0EgUm9vdCBDQTBZMBMGByqGSM49AgEGCCqGSM49
AwEHA0IABGLMpesofsSGL2HirTawqB5CMuUkMBHcc094adrjtitswuusfv5wV7/M
mRNFe2qZeCqjI0NNUUfwU2IMBjq1dyajRTBDMA4GA1UdDwEB/wQEAwIBBjASBgNV
HRMBAf8ECDAGAQH/AgEBMB0GA1UdDgQWBBSr+6VZ8yARwMVcLWWlnaDKzw1XtTAK
BggqhkjOPQQDAgNIADBFAiBcXR7okEjLYFfJjhrYqFJSESqfU3t7CKzy7+xLwkLD
LQIhAJG6Q5lfcsDWmS7M+KMWf19H/ZaHqgrPBwgCA9sc5kl+
-----END CERTIFICATE-----
EOL


echo -e $YELLOW "You need to have SSL Certificate at folder at ${PWD}" $NC
echo -e $YELLOW "SSL name should be  localssl.crt  and localssl.key at at ${PWD}" $NC
echo -e $GREEN  "IMPOIRTANT!" $NC
echo -e $YELLOW "root.crt certificate needs to be added to all your browsers and Android phones to access this private ssl certificate." $NC
echo -e $YELLOW "Note: a working certificate has been created for you. but you can replace it with your own." $NC


#register the root.crt so that NOW identifies it to validate ssl certificates.
echo "export NODE_EXTRA_CA_CERTS=/home/$USER/ssl/root.crt" | sudo tee -a /etc/profile

read -p "Press any key to proceed " k


###################################### DNS 

echo  "${IP}          {$DOMAIN_NAME}" | sudo tee -a  /etc/hosts

echo -e $GREEN "Install DNS Server and register your domain" $NC
sudo apt install -y dnsmasq

echo -e $BLUE "Configure DNS" $NC
sudo mv /etc/dnsmasq.conf  /etc/dnsmasq.conf.bak
#sudo touch /etc/dnsmasq.conf 
sudo bash -c "cat > /etc/dnsmasq.conf  <<EOL
listen-address=::1,127.0.0.1,${IP}
server=8.8.8.8
server=8.8.4.4
address=/${DOMAIN_NAME}/${IP}
cache-size=1000
EOL
"
sudo systemctl restart dnsmasq


echo -e $YELLOW "IMPORTANT:" $NC
echo -e $YELLOW "Set the DNS server address as the Raspberry Pi address ( ${IP} )on the device you want to configure. The DNS server address is in the network settings and differs depending on the OS in use." $NC


read -p "Press any key to proceed " k

###################################### NODEJS 


if command -v node &>/dev/null; then
  echo -e "${GREEN}Node.js is already installed. Skipping installation.${NC}"
else
  echo -e $GREEN "Install NodeJS" $NC
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt-get update
  sudo apt-get install nodejs -y
  sudo npm install -g npm@latest
fi
node -v
npm -v

read -p "Press any key to proceed " k

###################################### PM2
 
echo -e $GREEN "Install PM2" $NC
sudo npm install -g pm2  -timeout=9999999
pm2 startup


###################################### GIT

echo -e $GREEN "Install GIT" $NC
sudo apt install -y git


###################################### NODE-HTTP-SERVER
echo -e $GREEN "Install Http-Server & Serve" $NC
sudo npm install http-server -g -timeout=9999999
sudo npm install serve -g -timeout=9999999


###################################### Local Maps

echo -e $GREEN "Install Local Maps" $NC
mkdir ~/map ~/map/cachedMap


pushd  ~/map/cachedMap
echo -e $YELLOW "Put cached IMAGES at ${PWD}" $NC
sudo pm2 startup
sudo pm2 start http-server  -n map_server -x  -- ~/map/cachedMap  -p 88 -C ~/ssl/fullchain.pem -K ~/ssl/privkey.pem  --ssl
sudo pm2 save
sudo pm2 list
echo -e $YELLOW "Images are exposed as https://${DOMAIN_NAME}:88/." $NC
echo -e $YELLOW "You need to make webclient uses these images as a map. Please checl WebClient help at https://cloud.ardupilot.org" $NC
echo -e $YELLOW "for mode info check this video: https://youtu.be/ppwuUqomxXY" $NC
popd
read -p "Press any key to proceed " k



###################################### DroneEngage-Authenticator

echo -e $GREEN "DroneEngage-Authenticator" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch ${REPOSITORY_AUTH} --depth 1 ./droneengage_authenticator

pushd ~/droneengage_authenticator
echo -e $BLUE "installing nodejs modules" $NC
npm install -timeout=9999999 
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_auth
sudo pm2 start server.js  -n droneengage_auth
sudo pm2 save
popd

###################################### DroneEngage-Server

echo -e $GREEN "DroneEngage-Server" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch ${REPOSITORY_SERVER} --depth 1 ./droneengage_server

echo -e $BLUE "installing nodejs modules" $NC
pushd ~/droneengage_server
npm install -timeout=9999999
cd server
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
cd ..
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_server
sudo pm2 start server.js  -n droneengage_server
sudo pm2 save
popd




###################################### DroneEngage-WebClient

echo -e $GREEN "DroneEngage-Webclient" $NC
echo -e $BLUE "downloading release code" $NC
cd ~

git clone -b release --single-branch ${REPOSITORY_WEBCLIENT} --depth 1 ./droneengage_webclient

echo -e $BLUE "installing nodejs modules" $NC
pushd ~/droneengage_webclient
npm install -timeout=9999999
npm run build


echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete webclient
SERVE_ROOT=$(npm root -g)
sudo pm2 start $SERVE_ROOT/serve/build/main.js  -n webclient -- -s build -l 8881 --ssl-cert $HOME/ssl/fullchain.pem --ssl-key $HOME/ssl/privkey.pem
sudo pm2 save
popd

#git pull origin release --rebase



