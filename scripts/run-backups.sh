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

cloud_deploy(){
  :
  # sudo rclone sync ${ROOT_DIR}/backups b2:twio-data-backup
  # sudo rclone cleanup b2:twio-data-backup
}

stage_nextcloud(){

## Per Nextcloud docs (https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)

  echo "Staging Nextcloud..."
  # Enable maintenance mode
  docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --on

  # Remove junk from backups/tmp folder
  sudo rm -rf ${ROOT_DIR}/backups/tmp && sudo mkdir ${ROOT_DIR}/backups/tmp

  echo "Copying files to local from Nextcloud Docker container"
  # Grab files from Docker container in temp folder
  sudo docker cp nextcloudapp:/var/www/html/data ${ROOT_DIR}/backups/tmp
  sudo docker cp nextcloudapp:/var/www/html/themes ${ROOT_DIR}/backups/tmp
  sudo docker cp nextcloudapp:/var/www/html/config ${ROOT_DIR}/backups/tmp

  # Dump database

  archive_name="$(hostname)-$(date -Iseconds | cut -d '+' -f 1)"
  borg_options="--stats --compression zlib"
  echo "Creating ${ROOT_DIR}/backups/borg-repo::${archive_name}-nextcloud"
  sudo borg create ${borg_options} ${ROOT_DIR}/backups/borg-repo::${archive_name}"-nextcloud" \
   ${ROOT_DIR}/backups/tmp/data \
   ${ROOT_DIR}/backups/tmp/themes \
   ${ROOT_DIR}/backups/tmp/config  \
   ${ROOT_DIR}/tim/files/Apps/pico # \ Add custom directories here (include backslash+new line)

   echo "Removing local copies of data"
   sudo rm -rf ${ROOT_DIR}/backups/tmp && sudo mkdir ${ROOT_DIR}/backups/tmp

   # Enable maintenance mode
   docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --off
}

prune_borg(){
  sudo borg prune \
   --stats \
   --keep-daily 14 \
   --keep-weekly 4 \
   --keep-monthly 6 \
   --keep-yearly -1 \
   ${ROOT_DIR}/backups/borg-repo
}

stage_nextcloud
#prune_borg
echo "Successfully backed up: ${archive_name}" >> /home/$USER/backups.log
