RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

sudo pm2 startup

echo -e $GREEN "droneengage_authenticator" $NC
pushd ~/droneengage_authenticator
git stash save "any modification"
git pull origin release
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_auth
sudo pm2 start server.js  -n droneengage_auth
sudo pm2 save
popd


echo -e $GREEN "droneengage_server" $NC
pushd ~/droneengage_server
git stash save "any modification"
git pull origin release
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete droneengage_server
sudo pm2 start server.js  -n droneengage_server
sudo pm2 save
popd

echo -e $GREEN "droneengage_webclient" $NC
pushd ~/droneengage_webclient
git stash save "any modification"
git pull origin release
echo -e $BLUE "register as a service in pm2" $NC
sudo pm2 delete webclient
sudo pm2 start server.js  -n webclient
sudo pm2 save
popd



sudo pm2 restart all


