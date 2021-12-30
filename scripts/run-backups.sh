#!/bin/bash

# TODO - convert to twio ecosystem
FILE=./.env

if [ -f $FILE ]; then
  echo ".env file exists; exporting vars"
  export $(cat .env | xargs)
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

archive_name="$(hostname)-$(date -Iseconds | cut -d '+' -f 1)"
borg_options="--stats --compression zlib"
sudo borg create ${borg_options} ${ROOT_DIR}/backups/borg-repo::${archive_name} \
 ${ROOT_DIR}/tim/files/Apps/pico/  # \ Add custom directories here (include backslash+new line)

# Set Borg parameters accordingly
sudo borg prune \
 --stats \
 --keep-daily 14 \
 --keep-weekly 4 \
 --keep-monthly 6 \
 --keep-yearly -1 \
 ${ROOT_DIR}/backups

cloud_deploy(){
  :
  # sudo rclone sync ${ROOT_DIR}/backups b2:twio-data-backup
  # sudo rclone cleanup b2:twio-data-backup
}

stage_nextcloud(){
  :
}

echo "Successfully backed up: ${archive_name}" >> /home/$USER/backups.log
