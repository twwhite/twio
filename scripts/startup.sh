#!/bin/bash

cd /twio/scripts/

import_env(){
  # Import .env vars -> Carries over to docker-compose.yml
  FILE=./.env

  if [ -f $FILE ]; then
    echo "Loading variables from $FILE"
    set -o allexport
    source $FILE
    set +o allexport
  else
    echo "Please setup a .env file according to the README.md"
    exit 1
  fi

  echo "Variables loaded!"
}


launch(){
  docker-compose down && docker-compose up -d
}

import_env
launch
