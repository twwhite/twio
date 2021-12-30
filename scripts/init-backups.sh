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
  echo "Installing Borg if not already installed..."
  hash borg 2>/dev/null || { sudo apt install borgbackup; :;}
}

init_borg_repo(){
  echo "Initializing local Borg repository in "$ROOT_DIR/backups/borg-repo""
  echo "Initializing local Borg repository in "$ROOT_DIR/backups/borg-repo"" >> /home/$USER/backups.log
  sudo borg init --encryption=repokey $ROOT_DIR/backups/borg-repo
  sudo borg config $ROOT_DIR/backups/borg-repo additional_free_space 2G # Pad the backup with 2G to ensure filesystem never gets full enough to crash Borg.
}

create_backup_service(){
  crontab -l > mycron
  # Run twice daily - 01 AM and 01 PM
  echo "00 01,13 * * * /twio/scripts/run-backups.sh" >> mycron
  sudo crontab mycron
  rm mycron
}

get_available_space
install_borg
init_borg_repo
#create_backup_service
