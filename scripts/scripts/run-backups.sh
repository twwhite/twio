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
# sudo mysqldump --all-databases > /twiodbdata/all-dbs-mysqldump.sql

borg_options="--stats --compression zlib"
borg create ${borg_options} ${ROOT_DIR}/backups::${archive_name} \
 ${ROOT_DIR}/tim/  # \ Add custom directories here (include backslash+new line)

# Set Borg parameters accordingly
borg prune \
 --stats \
 --keep-daily 14 \
 --keep-weekly 4 \
 --keep-monthly 6 \
 --keep-yearly -1 \
 ${ROOT_DIR}/backups

sudo rclone sync ${ROOT_DIR}/backups b2:twio-data-backup
sudo rclone cleanup b2:twio-data-backup

sudo echo "Successfully backed up: ${archive_name}" >> /var/log/backup.log
