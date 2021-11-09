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

get_wiki_files() {
	echo "get_wiki_files()"
}

#get_data_repo() {
#	# Get existing data if data repository set
#	if [[ -v DATA_REPOSITORY ]]; then git clone $DATA_REPOSITORY ./data; else echo "Skipping data. No repository set"; fi
#}

get_picocms
#get_data_repo



docker network create --driver bridge net || true
docker network create --driver bridge cloud-internal || true
docker network create --driver bridge php-internal || true

docker-compose up -d
