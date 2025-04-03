#!/bin/bash

###Air Gapped Server on AWS

DEFAULT_DOMAIN='mdtandruav.com'

IP='3.36.244.106'
MACHINE_IP=''
EXTERNAL_IP=''  ## same as MACHINE_IP if MACHINE_IP is real ip.
MIN_WEBRTC_PORTS=20000
MAX_WEBRTC_PORTS=40000
TURN_PWD='airgap:1234'

REPOSITORY_AUTH='https://github.com/DroneEngage/droneenage_authenticator.git'
REPOSITORY_SERVER='https://github.com/DroneEngage/droneengage_server.git'
REPOSITORY_WEBCLIENT='https://github.com/DroneEngage/droneengage_webclient_react.git'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

sudo apt update

###################################### DISABLE APACHE
sudo systemctl stop apache2.service
sudo systemctl disable apache2.service

###################################### CERBOT

#+++++++++++++++++++++++++++++++++++++ DOMAIN QUERY


validate_domain() {
  local domain_regex="^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$"
  if [[ $1 =~ $domain_regex ]]; then
    return 0
  else
    return 1
  fi
}



# Prompt the user for the domain name
while true; do
  read -p "$(echo -e "${GREEN}Enter the domain name (default: ${YELLOW}$DEFAULT_DOMAIN${GREEN}, press Enter to accept): ${NC}")" DOMAIN
  DOMAIN_NAME=${DOMAIN_NAME:-$DEFAULT_DOMAIN}
  echo "$(echo -e "${GREEN}You chose: ${YELLOW}$DOMAIN_NAME"${NC})"
  
  # Validate the domain syntax
  if validate_domain "$DOMAIN_NAME"; then
    read -p "$(echo -e "${GREEN}Is this correct? (y/n) ${NC}")" CONFIRM
    case $CONFIRM in
      [yY]* ) break;;
      [nN]* ) continue;;
      * ) echo "$(echo -e "${RED}Please answer yes or no.${NC}")";;
    esac
  else
    echo "$(echo -e "${RED}Invalid domain syntax. Please enter a valid domain.${NC}")"
  fi
done

#+++++++++++++++++++++++++++++++++++++ EOF DOMAIN QUERY


sudo apt install -y certbot python3-certbot-apache
sudo certbot certonly --standalone --domain $DOMAIN_NAME

sudo chmod -R 755 /etc/letsencrypt/live/

echo -e $BLUE "Create renew_ssl.sh file for auto renewal" $NC

touch /home/$USER/renew_ssl.sh
cat > /home/ubuntu/renew_ssl.sh <<EOL
#!/bin/bash
sudo certbot certonly -d ${DOMAIN_NAME} --standalone --force-renewal
EOL

sudo chmod +x renew_ssl.sh

echo -e $BLUE "Add a monthly task in crontab" $NC

sudo echo "@monthly  /home/$USER/renew_ssl.sh >/dev/null 2>&1" | sudo crontab -

echo -e $BLUE "Create SSL folder" $NC

sudo ln -s  /etc/letsencrypt/live/$DOMAIN_NAME /home/$USER/ssl 

read -p "Press any key to proceed " k


###################################### COTURN

echo -e $GREEN "Install CoTurn" $NC
sudo apt install -y coturn

echo -e $BLUE "Run CoTurn as a Service" $NC
sudo mv /etc/turnserver.conf  /etc/turnserver.conf.old

sudo touch /etc/turnserver.conf 
sudo bash -c "cat > /etc/turnserver.conf  <<EOL
listening-port=3478
tls-listening-port=5349
listening-ip=${MACHINE_IP}
relay-ip=${MACHINE_IP}
external-ip=${EXTERNAL_IP}/${MACHINE_IP}
min-port=${MIN_WEBRTC_PORTS}
max-port=${MAX_WEBRTC_PORTS}
fingerprint
lt-cred-mech
server-name=${DOMAIN_NAME}
user=${TURN_PWD}
EOL
"

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
  NODE_MAJOR=18
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  sudo apt-get update
  sudo apt-get install nodejs -y
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

###################################### GIT

echo -e $GREEN "Install GIT" $NC
if command -v git &>/dev/null; then
  echo -e "${GREEN}Git is already installed. Skipping installation.${NC}"
else
sudo apt install -y git
fi



###################################### NODE-HTTP-SERVER
echo -e $GREEN "Install Http-Server" $NC
sudo npm install http-server -g -timeout=9999999


###################################### Local Maps

echo -e $GREEN "Install Local Maps" $NC
mkdir ~/map ~/map/cachedMap


pushd  ~/map/cachedMap
echo -e $YELLOW "Put cached IMAGES at ${PWD}" $NC
sudo pm2 startup
sudo pm2 start http-server  -n map_server -x  -- ~/map/cachedMap  -p 88 -C ~/ssl/localssl.crt -K ~/ssl/localssl.key  --ssl
sudo pm2 save
sudo pm2 list
echo -e $YELLOW "Images are exposed as https://${DOMAIN_NAME}:88/." $NC
echo -e $YELLOW "You need to make webclient uses these images as a map. Please checl WebClient help at https://cloud.ardupilot.org" $NC
popd
read -p "Press any key to proceed " k


###################################### Andruav-Authenticator

echo -e $GREEN "DroneExtend-Authenticator" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch ${REPOSITORY_AUTH} --depth 1 ./de_authenticator

pushd ~/de_authenticator
echo -e $BLUE "installing nodejs modules" $NC
npm install -timeout=9999999 
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete de_auth
sudo pm2 start server.js  -n de_auth
sudo pm2 save
popd





###################################### Andruav-Server

echo -e $GREEN "DroneExtend-Server" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch ${REPOSITORY_SERVER} --depth 1 ./de_server

pushd ~/de_server
echo -e $BLUE "installing nodejs modules" $NC
npm install -timeout=9999999
cd server
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
cd ..
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete de_server
sudo pm2 start server.js  -n de_server
sudo pm2 save
popd




###################################### Andruav-WebClient

echo -e $GREEN "DroneEngage-Webclient" $NC
echo -e $BLUE "downloading release code" $NC
cd ~

git clone -b release --single-branch ${REPOSITORY_WEBCLIENT} --depth 1 ./de_webclient

echo -e $BLUE "installing nodejs modules" $NC
pushd ~/de_webclient

echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete webclient
SERVE_ROOT=$(npm root -g)
sudo pm2 start $SERVE_ROOT/serve/build/main.js  -n webclient -- -s build -l 8001 --ssl-cert $HOME/ssl/fullchain.pem --ssl-key $HOME/ssl/privkey.pem
sudo pm2 save
popd

#git pull origin release --rebase



