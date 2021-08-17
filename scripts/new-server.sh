#!/bin/bash

get_env_vars() {
	if [ ! -f .env ]
	then
	  export $(cat .env | xargs)
	fi
}

get_picocms() {
	# PicoCMS
	curl -sSL https://getcomposer.org/installer | php
	git clone --depth 1 $PICO_COMPOSER_REPOSITORY ./apps/picocms/html
	php composer.phar --working-dir=./apps/picocms/html/ install
}

get_data_repo() {
	# Get existing data if data repository set
	if [[ -v DATA_REPOSITORY ]]; then git clone $DATA_REPOSITORY ./data; else echo "Skipping data. No repository set"; fi
}

#get_env_vars
#get_picocms
#get_data_repo




docker network create --driver bridge net || true
docker-compose up -d
