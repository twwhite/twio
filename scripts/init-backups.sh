#!/bin/bash
FILE=./.env
if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

echo $BORG_BACKUP_FOLDER

get_available_space() {
  str_available_space=$(df -h "."  | awk 'NR==2{print $4}')
  echo "Available disk space: "$str_available_space
}

install_borg() {
  echo "Installing Borg if not already installed..."
  hash borg 2>/dev/null || { sudo apt install borgbackup; :;}
}

init_borg_repo(){
  echo "Initializing local Borg repository in "$BORG_BACKUP_FOLDER"/borg"
  sudo mkdir -p $BORG_BACKUP_FOLDER
  sudo borg init --encryption=repokey $BORG_BACKUP_FOLDER/borg
  sudo borg config $BORG_BACKUP_FOLDER/borg additional_free_space 2G # Pad the backup with 2G to ensure filesystem never gets full enough to crash Borg.
}

get_available_space
install_borg
init_borg_repo
