#!/bin/bash

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
  echo "Setting permissions for $FILE to be accessed only by $USER"
  sudo chmod 600 $FILE
}

init_config_files(){

  # Setup kanboard config file. Note: Plaintext pw stored; be careful not to sync this file, only sync the example.
  # TO-DO -> Switch from linked local directory to copying config file into Docker container at init.
  echo "Setting up Kanboard config file."
  rm -f ${ROOT_DIR}/apps/kanboard/config/config.php
  cp -i ${ROOT_DIR}/apps/kanboard/config/config.php.example ${ROOT_DIR}/apps/kanboard/config/config.php

  # Setup homer dashbaord config file.
  echo "Setting up Homer config file."
  rm -r ${ROOT_DIR}/apps/homer/conf.d/default.conf 2> /dev/null
  cp -ip ${ROOT_DIR}/apps/homer/conf.d/default.conf.example ${ROOT_DIR}/apps/homer/conf.d/default.conf
  sed -i "s/SERVERNAMEPLACEHOLDER/${DOMAIN}/" ${ROOT_DIR}/apps/homer/conf.d/default.conf

  # Setup db-init file for docker-compose (from template; see sed password replacements below)
  echo "Setting up DB-init file(s)."
  rm -f ./db-init/01.sql
  cp ./db-init/01.sql.bak ./db-init/01.sql


  if grep -Gq "DEFAULT_USER*" "$FILE"
  then
    sed -i "s/DEFAULT_USER.*//g" "$FILE"
    sed -ir '/^\s*$/d' "$FILE"
    DEFAULTUSER="${USER}"
  fi
  echo "DEFAULT_USER=$DEFAULTUSER">>.env

  echo "Config files init complete."


}

init_nextcloud_folders(){
  if [ ! -d ${ROOT_DIR}/apps/nextcloud/config ]; then
    mkdir ${ROOT_DIR}/apps/nextcloud/config
  fi
  if [ ! -d ${ROOT_DIR}/apps/nextcloud/themes ]; then
    mkdir ${ROOT_DIR}/apps/nextcloud/themes
  fi
  if [ ! -d ${ROOT_DIR}/apps/nextcloud/data ]; then
    mkdir ${ROOT_DIR}/apps/nextcloud/data
  fi
  sudo setfacl -R -m u:${DEFAULT_USER}:rwX ${ROOT_DIR}/apps/nextcloud/data
}

get_init_pico(){
  echo "Initiating PicoCMS"
  # Get and init PicoCMS
  if [[ $(find ${ROOT_DIR}/apps/pico/html -name "*.*") ]]
  then
    read -e -p "Files exist in ${ROOT_DIR}/apps/pico/html. Remove? (y/N)?  " x
    if [ $"$x" == "y" ]; then rm -rf ${ROOT_DIR}/apps/pico/html/*; fi
  fi
  git clone --depth 1 ${PICO_COMPOSER_REPOSITORY} ./tmp/pico-composer
  cp -r ./tmp/pico-composer/* ${ROOT_DIR}/apps/pico/html/
  cd ./tmp
  curl -sS https://getcomposer.org/installer | php
  php composer.phar --working-dir=${ROOT_DIR}/apps/pico/html/ install
  cd ${ROOT_DIR}/scripts
  rm -rf ${ROOT_DIR}/scripts/tmp/*
}

setup_secrets(){

  # TODO: Setup gpg keyfiles

  echo
  echo "== USER PASSWORD GENERATION =="
  echo "Caution: The following passwords will be automatically copied into the .env file in the directory of this script. Precautions should be taken to not allow undesired access to the file accordingly."
  declare -A secretsArray
  keys=("DB_ROOT_PASS" "DB_NEXTCLOUD_PASS" "DB_KANBOARD_PASS" "DB_FRESHRSS_PASS" "BORG_PASS")
  numKeys=${#keys[@]}
  i=1
  read -e -p "Generate 20-digit hex oepnssl rand passwords (to be stored in .env file)? (Y/n)" z
  if [ $"$x" == "z" ]; then randPass=1; fi
  for str in "${keys[@]}"; do
    if grep -Gq "$str*" "$FILE"
    then
      echo "PLEASE RECORD YOUR PASSWORDS IN CASE YOU NEED TO RECOVER FROM A BACKUP"
      read -e -p "$str exists, overwrite (y/N)? "  c
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
      if randPass==1
      then
        echo "Generating random password"
        a=$(openssl rand -hex 20)
        break
      else
        read -s -p $"($i/$numKeys) Please enter a password for $str: " a
        read -r -e -s -p $'\nConfirm password: ' b
        if [ "$a" == "$b" ]; then break; else echo $'\nPasswords did not match'; fi
      fi
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
  sed -i "s/kanboardpasswordplaceholder/${DB_KANBOARD_PASS}/" ${ROOT_DIR}/apps/kanboard/config/config.php
  echo
}

freshrss_db_init(){
  sed -i "s/freshrsspasswordplaceholder/${DB_FRESHRSS_PASS}/" ./db-init/01.sql
  echo
  # sudo sed -i "s/kanboardpasswordplaceholder/${DB_KANBOARD_PASS}/" ${ROOT_DIR}/apps/kanboard/config/config.php
  # echo
}

setup_docker_networks(){
  # Setup Docker networks
  docker network create --driver bridge net || true
  docker network create --driver bridge cloud-internal || true
  docker network create --driver bridge php-internal || true
}

setup_systemd_services(){
  # Setup Systemd service for persistent reboots
  echo "Copying twio.service"
  sudo cp ./systemd/twio.service /etc/systemd/system/
  echo "Reloading daemon"
  sudo systemctl daemon-reload
  echo "Enabling twio.service"
  sudo systemctl enable twio.service

  # sudo systemctl start twio.service
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

  if [ $attempt -gt 10 ]; then
    echo "Error: $2 not responding, cancelling set up"
    exit 1
  fi
}

cleanup(){
  rm ./db-init/01.sql
}

init_backups(){
  :
}

launch_db(){
  docker-compose down && docker-compose up -d db
}

launch() {
  echo "Launching! (This step may take a while, please wait...)"
  ./startup.sh
  echo "Launch complete."

}

init_backups(){
  # echo 'Starting init-backup script...'
  bash ./init-backups.sh
}

import_env
init_config_files
init_nextcloud_folders
get_init_pico
setup_secrets
kanboard_db_init
freshrss_db_init
setup_docker_networks
setup_systemd_services
launch_db
waitUntilServiceIsReady dbIsReady "MariaDB"
launch
cleanup
init_backups
