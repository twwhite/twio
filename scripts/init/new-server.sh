#!/bin/bash

FILE=./.env

if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Nope .env file"
fi

get_picocms() {
	# PicoCMS
	curl -sSL https://getcomposer.org/installer | php
	rm -rf ../../apps/picocms/html
	git clone --depth 1 $PICO_COMPOSER_REPOSITORY ../../apps/picocms/html
	php composer.phar --working-dir=../../apps/picocms/html/ install
}


get_picocms


docker network create --driver bridge net || true
docker network create --driver bridge cloud-internal || true
docker network create --driver bridge php-internal || true

docker-compose up -d
