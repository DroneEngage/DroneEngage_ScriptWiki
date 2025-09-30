#!/bin/bash

# Air Gapped Server Setup Script for Raspberry Pi 4 (Raspbian Bullseye)
# Version: 4.5.0
# Description: This script automates the setup of an air-gapped server for DroneEngage.
# Prerequisites: Raspberry Pi 4, Raspbian Bullseye, sudo privileges.
# Author: Mohammad Hefny
# Repository: https://github.com/DroneEngage/DroneEngage_ScriptWiki

SCRIPT_VERSION='4.5.0'

ACTIVATE_AP=FALSE
AP_SSID='DE_SERVER'
AP_PWD='droneengage'
AP_IP='192.169.9.1/24'

#Actual Domain Name will have .local - DO NOT WRITE .local in the name it will be added automatically.
DOMAIN_NAME='airgap' 
MIN_WEBRTC_PORTS=20000
MAX_WEBRTC_PORTS=40000
TURN_PWD='airgap:1234' ## check https://cloud.ardupilot.org/webclient-configuration.html

## NODEJS Version
NODE_MAJOR=22


REPOSITORY_AUTH='https://github.com/DroneEngage/droneenage_authenticator.git'
REPOSITORY_SERVER='https://github.com/DroneEngage/droneengage_server.git'
REPOSITORY_WEBCLIENT='https://github.com/DroneEngage/droneengage_webclient_react.git'


RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

LOG_FILE="/var/log/droneengage_setup.log"



echo -e $YELLOW "INSTALLING AIRGAP SERVER FOR DRONEENGAGE" $NC
echo -e $YELLOW "For mode details: https://youtu.be/R1BedRTxuuY" $NC
echo -e $GREEN "script version $SCRIPT_VERSION"
read -p "Press any key to proceed " k


sudo apt update

###################################### Prepare tools
# Validation: Check if required tools (e.g., git, curl, wget) are installed before proceeding.
for cmd in git curl wget; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}$cmd is required but not installed. Installing...${NC}"
    sudo apt install -y "$cmd"
  fi
done

###################################### SSL 
## Rename Host
# Backup: Before modifying /etc/hosts or other system files, create backups.
sudo cp /etc/hosts /etc/hosts.bak
# 1. Set the static hostname (updates /etc/hostname)
sudo hostnamectl set-hostname "$DOMAIN_NAME"
# 2. Update /etc/hosts (manual fix for resolution)
echo -e $GREEN "Updating /etc/hosts to include $DOMAIN_NAME..." $NC
# Use sed to replace the existing 127.0.0.1 line to ensure it includes the new hostname.
# This assumes the original line looks like "127.0.0.1  localhost" or "127.0.0.1  oldname"
# The -i flag edits the file in place.
sudo sed -i "/^127.0.0.1\s\+/s/\(\s\+${DOMAIN_NAME}\)\?$/\t${DOMAIN_NAME}/" /etc/hosts
echo -e $GREEN "Hostname updated and local resolution configured." $NC

## Generate SSL
mkdir -p $HOME/ssl_local/ssl_airgap/
SSL_DIR="$HOME/ssl_local/ssl_airgap"


touch $SSL_DIR/domain.crt
cat > $SSL_DIR/domain.crt <<EOL
-----BEGIN CERTIFICATE-----
MIIFLTCCAxWgAwIBAgIUEAAGtGtkR2XRLMRQcO97JnlsQO8wDQYJKoZIhvcNAQEL
BQAwgZ4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMREwDwYDVQQH
DAhTYW4gSm9zZTEgMB4GA1UECgwXRHJvbmVFbmdhZ2UgUHJpdmF0ZSBQS0kxHjAc
BgNVBAsMFUNlcnRpZmljYXRlIEF1dGhvcml0eTElMCMGA1UEAwwcRHJvbmVFbmdh
Z2UgUHJvdmlkZXIgUm9vdCBDQTAeFw0yNTA5MjkyMDE4NDhaFw0zNTA5MjcyMDE4
NDhaMIGCMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTERMA8GA1UE
BwwIU2FuIEpvc2UxHDAaBgNVBAoME0Ryb25lRW5nYWdlIFN5c3RlbXMxFjAUBgNV
BAsMDUlUIE9wZXJhdGlvbnMxFTATBgNVBAMMDGFpcmdhcC5sb2NhbDCCASIwDQYJ
KoZIhvcNAQEBBQADggEPADCCAQoCggEBAI/MD1hBR+vYXTbKN0U6tWTxd7RDixyM
BRfdfmXAEt2tfWzbCLrVhgnEpDe/zsaPCVH5FRom9sj++lDB6n3qoxe2GGKttLyq
iU1IK/RldOm+5YJOtV8AvHXWyOMdEaxLfglwIXwulLJLC//dLsmxajAHGJxmTwtY
mYxnk/kKjfFwj5LzQKRIWk4KYmEe/ZzVCbs3Hax+vqsgqbJ121f3u9uACmS6AcgP
vNHRJJxZ+CiwZg2Xtzf9BWa4EHSLScd8+3tnhJlphdob0KUh7tf+i76zv3atzl0x
rFsZlrvlgsburQ9PxyC+1wf6TMCAH+5lvev5BDe78WpQ2fSH+9UTUxsCAwEAAaN9
MHswCwYDVR0PBAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBcGA1UdEQQQMA6C
DGFpcmdhcC5sb2NhbDAdBgNVHQ4EFgQUxETgCML8rKGu5arcRjPREIF43+AwHwYD
VR0jBBgwFoAUpNzFNVBy4eSa1Fy5XpdnvJSC5/YwDQYJKoZIhvcNAQELBQADggIB
AIc00LD89IHSc+g9YUX9tXXo0YVCrNrXExDyvUNQfDhZtGKQWe/XLgQiLR0ksy3f
5F3RWnG2Hks7EGNGS6o4eCAstl4H1wWuN1LGby31OOt8uJsNt2Y1NJgr9Ssr4cK8
TT2Xv1hqSxQXRAkGZXbXrz3/OGbj/UMUivqcfYvWkBMFyijRsSU1PxnPPUidwE8J
jQIOpwuB5eBAwY5h37MffSGEkU2tMV89owsh2WExmX0xe9kIvr7MOsjjdwVfM4Kk
A+RdlrnBBrTutCHKaDIUop9CrR1C9C/t+nafx6opXNtWTZoxd/U/cbY9If6qzkj9
pKlqsFFapdxeVk0HVaehIgHNBr5uRSUwfLnVwNCwKNXlt8OrqG9wbSeoyrcWhKSk
ir/U8nAwZEGmOTL1uORIjF1ctcNK+naAs9jn5hVCkmNsMm7HNjvyxvA1NSnu3G9i
XDBxlkwnoDTfMuhefet0LRJ0v45u4u5A1UT+z4gSV8Vl+Nvc7ZjLyASMbQ5GWChB
n2VinlZ0pBfk/XdsGE9IrzQVR4vL3HQYDndgXDPMca10KWI83IECAErEKByTqQ9l
fOIVuFJmE5cfpTmNO1IOiy93tFEedIGgZxzrNbFRYrt4bXEBOdZ90TjPE3uvuRQe
FXCwlMvPgR3qHm1v1qBdVwd6JXfQ1x67bOLfAvdIpza4
-----END CERTIFICATE-----
EOL

touch $SSL_DIR/domain.key
cat > $SSL_DIR/domain.key <<EOL
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCPzA9YQUfr2F02
yjdFOrVk8Xe0Q4scjAUX3X5lwBLdrX1s2wi61YYJxKQ3v87GjwlR+RUaJvbI/vpQ
wep96qMXthhirbS8qolNSCv0ZXTpvuWCTrVfALx11sjjHRGsS34JcCF8LpSySwv/
3S7JsWowBxicZk8LWJmMZ5P5Co3xcI+S80CkSFpOCmJhHv2c1Qm7Nx2sfr6rIKmy
ddtX97vbgApkugHID7zR0SScWfgosGYNl7c3/QVmuBB0i0nHfPt7Z4SZaYXaG9Cl
Ie7X/ou+s792rc5dMaxbGZa75YLG7q0PT8cgvtcH+kzAgB/uZb3r+QQ3u/FqUNn0
h/vVE1MbAgMBAAECggEADtWNdFx7rRa2JbD+Zau/oHO768KXXHEMv3Wv6ehC1KU7
+K8EkLL2r8BI8/Vba/wVM+R/FaJqYrl8cjinAP65J3jiEsqlCAeMatwPU22PU45y
wnAYjCiZHeDz+rX6J5eRdNYhUNxvUOX8DWpbFB8ze1PoE+OxXilxjFyiamvOe9cq
ElL31RiTX9NfkNKQ3Ptjj4CulGXHL639N5JHnZdTWMWxiabwhI7Ukruh3s9l4qFr
rg0xpAbLNlBP6YRowYx7zndBylHaYwbB4aG6BvXfNbww6KOyyYiohvi4SkpWERH0
1uULkPg3AFZMgMSgA6+/81VdRIE6pts0c9jI0rFuUQKBgQDEbFyMFoVDkmuIsvd1
AWIdfTMUVhIFGVG8hABxtloPSSMI7R73UJk5AFun/6O9ZFeWkN6b4laaDDY5tvPo
zVvkXvFgUsI36S9rjBQxzhAvTgFoCK+6w0w+zmYk3l4QoBHD7ggP93XxCohaliVR
YUlIQavraWznnakUDwVeJVBbSwKBgQC7aXHGR04HoODad9G6/2QIrUEg+AAuZdV7
J5LYf8KoeOddqxwCbT0hsc76JmK8XZ6qkDwWcqt9lOAaFXutKdFR99mMBgs5CA9U
OhFnxARUPQVRS60hRJtklu8ittN8C2JzrYy2rL3vM7AtVWI0gQQQHtAc4aBcQpxZ
70h3s821cQKBgQCCq0vN7dVtpGRhJh20+tyYnYdzieam+bcEYBQjkZnL/W2PLJ+j
Cz1DTFetJUV6YtxZz7onnaTbCjCwqGMOhj8RZ4/P8n49z6S6OQ/eKiVeMtiAqvas
meuJBKmy8TNGgBYRb7JxXMBbQBSBnszonH2x0e5ax2Gpm5q1O2Doxo30jQKBgGmg
V3CiNZdVFAXtrDZRxMajJ2b2f9ump3h+6GO/Ni4P3o7LZsDzYpYACiCwy8tQlKGb
I1KflIn2A4yP+SGyxPgG0gT6Tw74vPMCu1aZgrsbnUihd1WdvlsmOmd9VZq/K+D4
uqsmlvIfVrdmPTBMWsbfJvpwLBpzrH1/wH8+xrzxAoGBAKYZzTkFtR3inafpoV3I
UMa3CJkLPiCOw1NGJ0m6o8VnUq/xGQexlnZcWUGX/9cV+OH9hOTs+cI/jfwisPxQ
JUyiWdp5jfu/ddoeEEEMlUkK5eZFHM0kHXLxsE6tW9dmHufl5Fmgw7pl8bI1ZpCS
fZwHFgw3c0rGrTYo0gRzGib8
-----END PRIVATE KEY-----
EOL

touch $SSL_DIR/root.crt
cat > $SSL_DIR/root.crt <<EOL
-----BEGIN CERTIFICATE-----
MIIGLzCCBBegAwIBAgIUZHCrZun1UvEH0jSyuuGaTglJqIkwDQYJKoZIhvcNAQEL
BQAwgZ4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMREwDwYDVQQH
DAhTYW4gSm9zZTEgMB4GA1UECgwXRHJvbmVFbmdhZ2UgUHJpdmF0ZSBQS0kxHjAc
BgNVBAsMFUNlcnRpZmljYXRlIEF1dGhvcml0eTElMCMGA1UEAwwcRHJvbmVFbmdh
Z2UgUHJvdmlkZXIgUm9vdCBDQTAeFw0yNTA5MjkyMDE4NDZaFw0zNTA5MjcyMDE4
NDZaMIGeMQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTERMA8GA1UE
BwwIU2FuIEpvc2UxIDAeBgNVBAoMF0Ryb25lRW5nYWdlIFByaXZhdGUgUEtJMR4w
HAYDVQQLDBVDZXJ0aWZpY2F0ZSBBdXRob3JpdHkxJTAjBgNVBAMMHERyb25lRW5n
YWdlIFByb3ZpZGVyIFJvb3QgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
AoICAQCoffLx20fDmltINNRL/vlXuTidU8rsdaBHt4uZA/2WDjci6Ce9N/MgxqBI
oJcs/RTpM1KlNRjoppTB/7Eu9h99B3XThL+MRoMxCGSppCxyKvTBQm6aghYYwrfg
XyHMpivyvxEw5pgS3Oa+30u6livARN3rl4KIgxZaMHJZXvf+BKZrheYJKto7o21w
IWZMLWoenVM4TU36wNFBMfbDUXDUmzLYKTzmTVK+2wGe//rbKZHNQZ4kTY21UbLd
y+XfWQjhrSL46eTIEyMeMW4obeEksxmrLdnnqua9LX3NB+0FAlFbwRMxSoKMOhIB
248Jx5M/9/Hl41q38TGnRkUqMjJYj3E6UUHkeo+3p/dBuJHoQSV//4yatwcYXDx/
J7PAz9gukkKE2aT9Su3yTDpi2nxwyJ/yvf++Ris3DE1fu2i7qYw/QoBJDjPXH1In
YywJZBWiOeu/hbVcwLgH4FzfB1+05xZGQ86NkeLumnm03N7CVn/AlESA8bK29Bqk
y/4PdVWhQild2Rq7tq7lMD1qv9AebxMijMXDX2yybqc9J6BA8ePCcaTNxAtyYPIT
tugWuAf0g16NHP6RAhAbn+EtmFBeCCDDHhQlKCNW8DHbI95vdv9MMbCvv6x3q9kQ
Yxcn/XNYO907djOuDLJStI95rvUIB1Te4Kejt2cxY8ElPcUY4wIDAQABo2MwYTAd
BgNVHQ4EFgQUpNzFNVBy4eSa1Fy5XpdnvJSC5/YwHwYDVR0jBBgwFoAUpNzFNVBy
4eSa1Fy5XpdnvJSC5/YwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYw
DQYJKoZIhvcNAQELBQADggIBAFNd//RZdHC/GECnCYryYsZEuB4hUSVeTvDl4bs+
dqRdxqlCXv+NLugKjW+3k3XyTHWR33NUEq84mScye2q66LwUy1GaGXzPLAY1rDf2
9mJSygiKBuarvDe6GMa5R0zmO/cUeUasdgtKPHf8SHVPMHHhl/1WY8eQedrHwCOS
LWKvi/KU7oJGD5uC51YVXrzbBjafoGt5+F9oQpLUJjGBVXe9fJ1SZYo22ynOgZQp
tzQ/wrBWaVEetGjuUilOj4iX5n1ZQsucLTvHJYOOloDmwZHTSbZdD4B/ok3TUuwq
KaNIanewSmP9cYjEwCol7uFZsccmlFMoLI2MkJkTEUuYq/iwiBz/MliuMV8gyXav
GQEi9QWqpGjq35DyOrBLsQyvGUmALuUB8LN4DclTgrJeHcRHksl13QdKe388jtOk
/9eeTpaLfUTqA3sVIGZapmVUqaLwz3txNzRVdDnr+YfzofYmZJ2Gal3h6PzDN6KX
1z/f1m7+vj2oBE0pc/yohTZvSjqEQwd8lLFw4BM4O82hpodwg9y0MYK9tipojpUm
cj0qG565aQRi/5db6Cxcre+NIFqHF4ek7J1jYvukhtbKlDDh7Qy8ksVvEdxCS6i1
5b/4Tv9BZEl26U7cybOBY0zMtLA6VNC/ueyr0tI+dr4FfemAnbWZboVZYj2n/xGo
9Buc
-----END CERTIFICATE-----
EOL

echo -e $YELLOW "You need to have SSL Certificate at folder at $SSL_DIR" $NC
echo -e $YELLOW "SSL name should be  [domain.crt] and [domain.key] at at $SSL_DIR" $NC
echo -e $GREEN  "IMPOIRTANT!" $NC
echo -e $RED "${SSL_DIR}/root.crt " $NC
echo -e $YELLOW "The above certificate needs to be added to all your browsers and Android phones to access this private ssl certificate." $NC
echo -e $YELLOW "Note: a working certificate has been created for you. but you can replace it with your own." $NC
read -p "Press any key to proceed " k


#register the root.crt so that NOW identifies it to validate ssl certificates.
echo "export NODE_EXTRA_CA_CERTS=$SSL_DIR/root.crt" | sudo tee -a /etc/profile

read -p "Press any key to proceed " k

###################################### SSL



###################################### COTURN
echo -e $GREEN "Install CoTurn" $NC
sudo apt install -y coturn

echo -e $BLUE "Run CoTurn as a Service" $NC

sudo touch /etc/turnserver.conf 
sudo bash -c "cat > /etc/turnserver.conf <<EOL
listening-port=3478
tls-listening-port=5349
listening-ip=0.0.0.0
relay-ip=0.0.0.0
min-port=${MIN_WEBRTC_PORTS}
max-port=${MAX_WEBRTC_PORTS}
fingerprint
lt-cred-mech
server-name=${DOMAIN_NAME}
user=${TURN_PWD}
EOL"

sudo systemctl enable coturn
sudo systemctl start coturn

###################################### NODEJS 
# Check if Node.js is installed
if command -v node &>/dev/null; then
  INSTALLED_VERSION=$(node -v | cut -d. -f1 | tr -d 'v')
  if [[ "$INSTALLED_VERSION" -ge "$NODE_MAJOR" ]]; then
    echo -e "${GREEN}Node.js version $INSTALLED_VERSION is installed. Skipping installation.${NC}"
  else
    echo -e "${YELLOW}Node.js version $INSTALLED_VERSION is installed, but version $NODE_MAJOR is required. Updating...${NC}"
    # Remove existing Node.js to avoid conflicts
    sudo apt-get remove -y nodejs
    sudo apt-get purge -y nodejs
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
    # Install Node.js 22
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install nodejs -y
    sudo npm install -g npm@latest
  fi
else
  echo -e "${GREEN}Installing Node.js version $NODE_MAJOR...${NC}"
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt-get update
  sudo apt-get install nodejs -y
  sudo npm install -g npm@latest
fi

# Verify installed versions
echo -e "${GREEN}Node.js version installed:${NC}"
node -v
echo -e "${GREEN}npm version installed:${NC}"
npm -v


read -p "Press any key to proceed " k

###################################### PM2
echo -e "${BLUE}Checking if PM2 is installed...${NC}"
if command -v pm2 &>/dev/null; then
  echo -e "${GREEN}PM2 is already installed. Skipping installation.${NC}"
else
  echo -e "${GREEN}Installing PM2...${NC}"
  sudo npm install -g pm2 ---fetch-timeout=9999999
  sudo pm2 startup
  sudo pm2 save
fi
pm2 -v


###################################### NODE-HTTP-SERVER
echo -e $GREEN "Install Http-Server & Serve" $NC
sudo npm install http-server -g --fetch-timeout=9999999
sudo npm install serve -g --fetch-timeout=9999999


###################################### Local Maps
echo -e $GREEN "Install Local Maps" $NC
mkdir -p $HOME/map/cachedMap


pushd  $HOME/map/cachedMap
echo -e $YELLOW "Put cached IMAGES at ${PWD}" $NC
sudo pm2 startup
sudo pm2 start http-server  -n map_server -x  -- ~/map/cachedMap  -p 88 --ssl --cert $HOME/ssl_local/ssl_airgap/domain.crt --key $HOME/ssl_local/ssl_airgap/domain.key
sudo pm2 save
sudo pm2 list
echo -e $YELLOW "Images are exposed as https://${DOMAIN_NAME}:88/." $NC
echo -e $YELLOW "You need to make webclient uses these images as a map. Please check WebClient help at https://cloud.ardupilot.org" $NC
echo -e $YELLOW "for mode info check this video: https://youtu.be/ppwuUqomxXY" $NC
popd
read -p "Press any key to proceed " k

###################################### DroneEngage-Authenticator
echo -e $GREEN "DroneEngage-Authenticator" $NC
echo -e $BLUE "downloading release code" $NC
cd $HOME
git clone -b release --single-branch ${REPOSITORY_AUTH} --depth 1 ./droneengage_authenticator
if [[ ! -d droneengage_authenticator ]]; then
  echo -e "${RED}Failed to clone DroneEngage-Authenticator repository. Exiting.${NC}"
  exit 1
fi

pushd $HOME/droneengage_authenticator
echo -e $BLUE "installing nodejs modules" $NC

sudo apt install -y build-essential cmake libzmq3-dev pkg-config
npm install --fetch-timeout=9999999 
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Failed to install Node.js modules. Exiting.${NC}"
  exit 1
fi

echo -e $BLUE "linking ssl folder" $NC
ln -sf "${SSL_DIR}" ./ssl

echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_auth 2>/dev/null
sudo pm2 start server.js  -n droneengage_auth
sudo pm2 save
popd



###################################### DroneEngage-Server
echo -e $GREEN "DroneEngage-Server" $NC
echo -e $BLUE "downloading release code" $NC
cd $HOME
git clone -b release --single-branch ${REPOSITORY_SERVER} --depth 1 ./droneengage_server
if [[ ! -d droneengage_server ]]; then
  echo -e "${RED}Failed to clone DroneEngage-Server repository. Exiting.${NC}"
  exit 1
fi

echo -e $BLUE "installing nodejs modules" $NC
pushd $HOME/droneengage_server
npm install --fetch-timeout=9999999
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Failed to install Node.js modules. Exiting.${NC}"
  exit 1
fi

cd server
echo -e $BLUE "linking ssl folder" $NC
ln -sf "${SSL_DIR}" ./ssl
cd ..

echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_server 2>/dev/null
sudo pm2 start server.js  -n droneengage_server
sudo pm2 save
popd



###################################### DroneEngage-WebClient
echo -e $GREEN "DroneEngage-Webclient" $NC
echo -e $BLUE "downloading release code" $NC
cd ~

git clone -b release --single-branch ${REPOSITORY_WEBCLIENT} --depth 1 ./droneengage_webclient
if [[ ! -d droneengage_webclient ]]; then
  echo -e "${RED}Failed to clone DroneEngage-Webclient repository. Exiting.${NC}"
  exit 1
fi

echo -e $BLUE "installing nodejs modules" $NC
pushd $HOME/droneengage_webclient

echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete webclient 2>/dev/null
sudo pm2 start http-server -n webclient -- build -p 8001 --ssl --cert $HOME/ssl_local/ssl_airgap/domain.crt --key $HOME/ssl_local/ssl_airgap/domain.key
sudo pm2 save
popd



########################################
# Information
echo -e "${YELLOW}Please register $HOME/ssl_local/DroneEngage_Provider_CA/root.crt in your browser as a trusted Authority.${NC}"
echo -e "${YELLOW}Please check this video: https://youtu.be/R1BedRTxuuY?si=s46PWwH1Ir94havS&t=621 for support.${NC}"


######################################## Create Access Point
echo -e "${GREEN}Create Access Point${NC}"
echo -e "${YELLOW}Would you like to create a Wi-Fi access point for your server? (y/n)${NC}"
read -p "Enter your choice: " create_ap
if [[ "$create_ap" =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Setting up access point...${NC}"
  sudo systemctl stop dnsmasq
  sudo systemctl disable dnsmasq
  sudo systemctl stop hostapd
  sudo systemctl disable hostapd
  sudo nmcli con delete hotspot 2>/dev/null
  sudo nmcli con add type wifi ifname wlan0 con-name hotspot ssid "${AP_SSID}" autoconnect yes
  sudo nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
  sudo nmcli con modify hotspot wifi-sec.psk "${AP_PWD}"
  sudo nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
  sudo nmcli con modify hotspot ipv4.addresses "${AP_IP}"
  sudo nmcli con up hotspot
else
  echo -e "${YELLOW}Skipping access point setup.${NC}"
fi

echo -e "${YELLOW}Rebooting to apply access point settings...${NC}"
read -p "Press any key to reboot now " k
sudo reboot

######################################## FINISH
