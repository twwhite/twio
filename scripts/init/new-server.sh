#!/bin/bash

# Import .env vars -> Carries over to docker-compose.yml
FILE=./.env

if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

# Get and init PicoCMS
curl -sSL https://getcomposer.org/installer | php
rm -rf ../../apps/picocms/html
git clone --depth 1 $PICO_COMPOSER_REPOSITORY ../../apps/picocms/html
php composer.phar --working-dir=../../apps/picocms/html/ install

# User input passwords (no storage)
while :
do
        read -s -p $"Enter a MariaDB root password: " pass1
        read -r -e -s -p $'\nVerify password: ' pass2
        if [ "$pass1" == "$pass2" ]; then break; else echo $'\nPasswords did not match'; fi
done
NEXTCLOUD_MARIADB_ROOT_PASSWORD="$pass1"
export NEXTCLOUD_MARIADB_ROOT_PASSWORD
while :
do
	echo
        read -s -p $"Enter a Nextcloud DB user password: " pass3
        read -r -e -s -p $'\nVerify password: ' pass4
        if [ "$pass3" == "$pass4" ]; then break; else echo $'\nPasswords did not match'; fi
done
NEXTCLOUD_MARIADB_NEXTCLOUDPASS="$pass3"
export NEXTCLOUD_MARIADB_NEXTCLOUDPASS


# Setup Docker networks
docker network create --driver bridge net || true
docker network create --driver bridge cloud-internal || true
docker network create --driver bridge php-internal || true

#docker network create --driver overlay net-overlay

# Setup Systemd service for persistent reboots
sudo cp ./systemd/twio.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable twio.service

# Start up TWIO services
sudo systemctl start twio.service
./startup.sh
