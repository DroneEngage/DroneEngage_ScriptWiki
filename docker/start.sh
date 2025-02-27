#!/bin/bash


pushd ~/map/cachedMap
sudo pm2 startup
sudo pm2 start http-server -n map_server -x -- ~/map/cachedMap -p 88 -C ~/ssl/fullchain.pem -K ~/ssl/privkey.pem --ssl
sudo pm2 save
sudo pm2 list
echo -e $YELLOW "Images are exposed as https://${DOMAIN_NAME}:88/." $NC
popd


pushd ~/droneengage_authenticator
sudo pm2 start server.js -n droneengage_auth
sudo pm2 save
sudo pm2 list
echo -e $YELLOW "DroneEngage-Authenticator is running." $NC
popd

pushd ~/droneengage_server
sudo pm2 start server.js -n droneengage_server
sudo pm2 save
echo -e $YELLOW "DroneEngage-Server is running." $NC
popd

SERVE_ROOT=$(npm root -g)
pushd ~/droneengage_webclient
sudo pm2 start $SERVE_ROOT/serve/build/main.js -n webclient -- -s build -l 8001 --ssl-cert ~/ssl/fullchain.pem --ssl-key $HOME/ssl/privkey.pem
sudo pm2 save
echo -e $YELLOW "DroneEngage-Webclient is running." $NC
popd


# Keep the container running
tail -f /dev/null


