#!/bin/bash

# Define color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

############################################ DOMAIN QUERY

DEFAULT_DOMAIN="mdtandruav.com"

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
  DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}
  echo "$(echo -e "${GREEN}You chose: ${YELLOW}$DOMAIN"${NC})"
  
  # Validate the domain syntax
  if validate_domain "$DOMAIN"; then
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

############################################ EOF DOMAIN QUERY


# Install Certbot
sudo apt-get update
sudo apt-get install -y certbot

# Obtain a certificate for the domain using Certbot
sudo certbot certonly --standalone -d $DOMAIN
sudo chmod -R 755 /etc/letsencrypt/live/

# Create symbolic links to the certificate files in the user's home directory
cd ~
unlink ~/ssl
sudo ln -s /etc/letsencrypt/live/$DOMAIN    ~/ssl

echo "SSL/TLS certificate obtained and symbolic links created."


# Create the script file
touch ~/renew_domain.sh
cat > ~/renew_domain.sh <<EOL
#!/bin/bash
sudo certbot certonly -d $DOMAIN --standalone --force-renewal 
EOL

# Make the script executable
chmod +x renew_domain.sh

# Add a monthly cron job to run the script
sudo bash -c "echo "@monthly $(pwd)/renew_domain.sh" > /etc/cron.monthly/renew_domain"
(sudo crontab -l ; echo "@monthly $(pwd)/renew_domain.sh") | sudo crontab -
echo "Renewal script created and scheduled for monthly execution."
