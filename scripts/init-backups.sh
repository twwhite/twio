#!/bin/bash
FILE=./.env
if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

get_available_space() {
  str_available_space=$(df -h "."  | awk 'NR==2{print $4}')
  echo "Available disk space: "$str_available_space
}

install_borg() {
  echo "Checking if borgbackup installed..."
  hash borg 2>/dev/null || { sudo apt install borgbackup; :; }
}

init_borg_repo(){
  borg init --encryption=repokey /path/to/repo
}


get_available_space
install_borg
