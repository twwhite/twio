#!/bin/bash

import_env(){
  # Import .env vars -> Carries over to docker-compose.yml
  FILE=./.env

  if [ -f $FILE ]; then
    echo "Loading variables from $FILE"
    export $(cat .env | xargs)
  else
    echo "Please setup a .env file according to the README.md"
    exit 1
  fi
}

init_config_files(){
  # Setup kanboard config file. Note: Plaintext pw stored; be careful not to sync this file, only sync the example.
  # TO-DO -> Switch from linked local directory to copying config file into Docker container at init.
  sudo rm -f ${ROOT_DIR}/apps/kanboard/config/config.php
  sudo cp -i ${ROOT_DIR}/apps/kanboard/config/config.php.example ${ROOT_DIR}/apps/kanboard/config/config.php

  # Setup db-init file for docker-compose (from template; see sed password replacements below)
  sudo rm -f ./db-init/01.sql
  sudo cp ./db-init/01.sql.bak ./db-init/01.sql
}

get_init_pico(){
  # Get and init PicoCMS
  curl -sSL https://getcomposer.org/installer | php
  rm -rf ${ROOT_DIR}/apps/picocms/html
  git clone --depth 1 $PICO_COMPOSER_REPOSITORY ${ROOT_DIR}/apps/picocms/html
  php composer.phar --working-dir=${ROOT_DIR}/apps/picocms/html/ install
}

setup_secrets(){
  echo
  echo "== USER PASSWORD GENERATION =="
  echo "Caution: The following passwords will be automatically copied into the .env file in the directory of this script. Precautions should be taken to not allow undesired access to the file accordingly."
  declare -A secretsArray
  keys=("DB_ROOT_PASS" "DB_NEXTCLOUD_PASS" "DB_KANBOARD_PASS" "BORG_PASS")
  numKeys=${#keys[@]}
  i=1
  for str in "${keys[@]}"; do
    if grep -Gq "$str*" "$FILE"
    then
      read -e -p "$str exists, overwrite (y/N)?  " c
      if ! [ $"$c" == "y" ]
      then
        continue
      else
        sed -i "s/$str.*//g" "$FILE"
        sed -ir '/^\s*$/d' "$FILE"
      fi
    fi
    while :
    do
      read -s -p $"($i/$numKeys) Please enter a password for $str: " a
      read -r -e -s -p $'\nConfirm password: ' b
      if [ "$a" == "$b" ]; then break; else echo $'\nPasswords did not match'; fi
    done
    secretsArray[$str]=$a
    echo "$str=$a">>.env
    i=$(($i+1))
    echo
  done
  import_env

}

kanboard_db_init(){
  sed -i "s/kanboardpasswordplaceholder/${DB_KANBOARD_PASS}/" ./db-init/01.sql
  echo
  sudo sed -i "s/kanboardpasswordplaceholder/${DB_KANBOARD_PASS}/" ${ROOT_DIR}/apps/kanboard/config/config.php
  echo
}

setup_docker_networks(){
  # Setup Docker networks
  docker network create --driver bridge net || true
  docker network create --driver bridge cloud-internal || true
  docker network create --driver bridge php-internal || true

}

setup_systemd_services(){
  # Setup Systemd service for persistent reboots
  sudo cp ./systemd/twio.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable twio.service
  # Start up TWIO services
  sudo systemctl start twio.service
}

dbIsReady() {
  docker-compose logs db | grep "MariaDB init process done. Ready for start up."
}

waitUntilServiceIsReady() {
  attempt=1
  # Try 10 times
  while [ $attempt -le 10 ]
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

cleanup(){
  read -p 'Remove local plain-text password containing DB-init file (y/n)?  ' ans
  if ans="y"; then rm ./db-init/01.sql; fi
}

launch() {
  ./startup.sh
}

init_backups(){
  :
  # echo 'Starting init-backup script...'
  # sudo bash ./init-backups.sh
}

import_env
init_config_files
get_init_pico
setup_secrets
kanboard_db_init
setup_docker_networks
setup_systemd_services
launch
waitUntilServiceIsReady dbIsReady "MariaDB"
cleanup
init_backups
