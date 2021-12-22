#!/bin/bash

FILE=./.env

if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

get_picocms() {
	# PicoCMS
	curl -sSL https://getcomposer.org/installer | php
	rm -rf ../../apps/picocms/html
	git clone --depth 1 $PICO_COMPOSER_REPOSITORY ../../apps/picocms/html
	php composer.phar --working-dir=../../apps/picocms/html/ install
}

get_picocms

# Setup Docker networks
docker network create --driver bridge net || true
docker network create --driver bridge cloud-internal || true
docker network create --driver bridge php-internal || true

# Setup Systemd service for persistent reboots
sudo cp ./systemd/twio.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable twio.service

# Start up TWIO services
sudo systemctl start twio.service
