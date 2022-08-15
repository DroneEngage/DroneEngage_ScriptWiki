#!/bin/bash

###Air Gapped Server on Raspberry PI

DOMAIN_NAME='airgap.droneengage.com'
IP='192.168.1.161'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

sudo apt update


###################################### COTURN
echo -e $GREEN "Install CoTurn" $NC
sudo apt install -y coturn

echo -e $BLUE "Run CoTurn as a Service" $NC
sudo touch /lib/systemd/system/andruav_turn.service
sudo bash -c "cat > /lib/systemd/system/andruav_turn.service <<EOL
[Unit]
 Description=Ardruav Turn Server
 After=multi-user.target

#Wants=network-online.target
#After=network.target

 [Service]
 Type=single
 ExecStart=/usr/bin/turnserver -L ${DOMAIN_NAME} -a -f -r ${DOMAIN_NAME} -v --user airgap:1234 --simple-log


 Restart=on-failure

 [Install]
 WantedBy=multi-user.target

EOL
"
sudo systemctl enable andruav_turn.service
sudo systemctl start andruav_turn.service



###################################### SSL 

mkdir -p ~/ssl


touch ~/ssl/localssl.crt
cat > ~/ssl/localssl.crt <<EOL
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

touch ~/ssl/localssl.key
cat > ~/ssl/localssl.key <<EOL
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


pushd ~/ssl
echo -e $YELLOW "You need to have SSL Certificate at folder at ${PWD}" $NC
echo -e $YELLOW "SSL name should be  localssl.crt  and localssl.key at at ${PWD}" $NC
echo -e $YELLOW "root.crt certificate needs to be added to all your browsers and Android phones to access this private ssl certificate." $NC
echo -e $YELLOW "A working certificate has been created for you. but you can replace it with your own." $NC
popd

#register the root.crt so that NOW identifies it to validate ssl certificates.
echo 'export NODE_EXTRA_CA_CERTS=/home/pi/ssl/root.crt' | sudo tee -a /etc/profile

read -p "Press any key to proceed " k


###################################### DNS 

echo  "${IP}          airgap.droneengage.com" | sudo tee -a  /etc/hosts

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

echo -e $GREEN "Install NodeJS" $NC
curl -sSL https://deb.nodesource.com/setup_16.x | sudo bash -
sudo apt install -y nodejs


###################################### PM2
 
echo -e $GREEN "Install PM2" $NC
sudo npm install -g pm2 
pm2 startup


###################################### GIT

echo -e $GREEN "Install GIT" $NC
sudo apt install -y git


###################################### NODE-HTTP-SERVER
echo -e $GREEN "Install Http-Server" $NC
sudo npm install http-server -g


###################################### Local Maps

echo -e $GREEN "Install Local Maps" $NC
mkdir ~/map ~/map/cachedMap


pushd  ~/map/cachedMaps
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

echo -e $GREEN "Andruav-Authenticator" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch https://github.com/HefnySco/andruav_authenticator.git --depth 1

pushd ~/andruav_authenticator
echo -e $BLUE "installing nodejs modules" $NC
npm install
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete andruav_auth
sudo pm2 start server.js  -n andruav_auth
sudo pm2 save
popd





###################################### Andruav-Server

echo -e $GREEN "Andruav-Server" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch https://github.com/HefnySco/andruav_server.git --depth 1

echo -e $BLUE "installing nodejs modules" $NC
pushd ~/andruav_server
npm install
cd server
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
cd ..
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete andruav_server
sudo pm2 start server.js  -n andruav_server
sudo pm2 save
popd




###################################### Andruav-WebClient

echo -e $GREEN "andruav_webclient" $NC
echo -e $BLUE "downloading release code" $NC
cd ~
git clone -b release --single-branch https://github.com/HefnySco/andruav_webclient.git --depth 1

echo -e $BLUE "installing nodejs modules" $NC
pushd ~/andruav_webclient
npm install
echo -e $BLUE "linking ssl folder" $NC
ln -s ~/ssl ./ssl
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete webclient
sudo pm2 start server.js  -n webclient
sudo pm2 save
popd

#git pull origin release --rebase



