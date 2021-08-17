#! /usr/bin/env bash

# TODO - convert to twio ecosystem

#archive_name="$(hostname)-$(date -Iseconds | cut -d '+' -f 1)"
#sudo mysqldump --all-databases > /twiodbdata/all-dbs-mysqldump.sql
#borg_options="--stats --compression zlib"
#borg create ${borg_options} /twiodata/backups::${archive_name} \
#  /twiodata/tim/ \
#  /var/www/ \
#  /etc/nginx/sites-available/ \
#  /twiodbdata/

#borg prune \
#  --stats \
#  --keep-daily 14 \
#  --keep-weekly 4 \
#  --keep-monthly 6 \
#  --keep-yearly -1 \
#  /twiodata/backups

#sudo rclone sync /twiodata/backups b2:twio-data-backup
#sudo rclone cleanup b2:twio-data-backup

#sudo echo "Successfully backed up: ${archive_name}" >> /var/log/backup.log
