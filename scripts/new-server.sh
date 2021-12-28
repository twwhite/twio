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


# Setup kanboard config file. Note: Plaintext pw stored; be careful not to sync this file, only sync the example.
sudo rm -f ${ROOT_DIR}/apps/kanboard/config/config.php
sudo cp -i ${ROOT_DIR}/apps/kanboard/config/config.php.example ${ROOT_DIR}/apps/kanboard/config/config.php

echo

# Setup db-init file for docker-compose (from template; see sed password replacements below)
sudo rm -f ./db-init/01.sql
sudo cp ./db-init/01.sql.bak ./db-init/01.sql

# Get and init PicoCMS
curl -sSL https://getcomposer.org/installer | php
rm -rf ${ROOT_DIR}/apps/picocms/html
git clone --depth 1 $PICO_COMPOSER_REPOSITORY ${ROOT_DIR}/apps/picocms/html
php composer.phar --working-dir=${ROOT_DIR}/apps/picocms/html/ install

# User input passwords (no storage)
## NEXTCLOUD MARIADB ROOT USERPASS
while :
do
        read -s -p $"(1/3) Enter a MariaDB root password: " pass1
        read -r -e -s -p $'\nVerify password: ' pass2
        if [ "$pass1" == "$pass2" ]; then break; else echo $'\nPasswords did not match'; fi
done
NEXTCLOUD_MARIADB_ROOT_PASSWORD="$pass1"
export NEXTCLOUD_MARIADB_ROOT_PASSWORD

## NEXTCLOUD DB USERPASS
while :
do
	echo
        read -s -p $"(2/3) Enter a Nextcloud DB user password: " pass3
        read -r -e -s -p $'\nVerify password: ' pass4
        if [ "$pass3" == "$pass4" ]; then break; else echo $'\nPasswords did not match'; fi
done
NEXTCLOUD_MARIADB_NEXTCLOUDPASS="$pass3"
export NEXTCLOUD_MARIADB_NEXTCLOUDPASS

## KANBOARD DB USERPASS
while :
do
	echo
        read -s -p $"(3/3) Enter a Kanboard DB user password: " pass5
        read -r -e -s -p $'\nVerify password: ' pass6
        if [ "$pass5" == "$pass6" ]; then break; else echo $'\nPasswords did not match'; fi
done
KANBOARD_MARIADB_PASSWORD="$pass6"
#export KANBOARD_MARIADB_PASSWORD

sed -i "s/kanboardpasswordplaceholder/${pass6}/" ./db-init/01.sql
echo
sudo sed -i "s/kanboardpasswordplaceholder/${pass6}/" ${ROOT_DIR}/apps/kanboard/config/config.php
echo


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

function dbIsReady() {
  docker-compose logs db | grep "MariaDB init process done. Ready for start up."
}

MAX_TRIES=10

function waitUntilServiceIsReady() {
  attempt=1
  while [ $attempt -le $MAX_TRIES ]
  do
    if "$@"; then
      echo "$2 container is up!"
      break
    fi
    echo "Waiting for $2 container... (attempt: $((attempt++)))"
    sleep 5
  done

  if [ $attempt -gt $MAX_TRIES ]; then
    echo "Error: $2 not responding, cancelling set up"
    exit 1
  fi
}

waitUntilServiceIsReady dbIsReady "MariaDB"

echo
read -p 'Remove local plain-text password containing files (y/n)?  ' ans
if ans="y"; then rm ./db-init/01.sql; fi
