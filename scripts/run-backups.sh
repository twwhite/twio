#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

# Do no change this value, it is auto-populated by the init_backups script.
ROOT_DIR=/twio

# TODO - convert to twio ecosystem
FILE=${ROOT_DIR}/scripts/.env

if [ -f $FILE ]; then
  echo "Loading variables from $FILE"
  set -o allexport
  source $FILE
  set +o allexport
else
  echo "Please setup a .env file according to the README.md"
  exit 1
fi

cloud_deploy(){
  :
  # sudo rclone sync ${ROOT_DIR}/backups b2:twio-data-backup
  # sudo rclone cleanup b2:twio-data-backup
}

borg_create(){
  echo
  echo "STAGING ${BACKUP_SERVICE} BACKUP"
  archive_name="$(date -Iseconds | cut -d '+' -f 1)-${BACKUP_SERVICE}"
  borg_options="--stats --compression zlib"
  echo $(date)": ${BACKUP_SERVICE} - Creating ${ROOT_DIR}/backups/borg-${BACKUP_SERVICE}::${archive_name}" >> ${ROOT_DIR}/scripts/logs/backups.log
  sudo BORG_PASSPHRASE=${BORG_PASS} borg create ${borg_options} ${ROOT_DIR}/backups/borg-${BACKUP_SERVICE}::${archive_name} "${BACKUP_DIRECTORIES[*]}"
}

stage_nextcloud(){

  ## Per Nextcloud docs (https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)

  BACKUP_SERVICE="nextcloud"
  BACKUP_DIRECTORIES=("${ROOT_DIR}/backups/tmp/")

  # Enable maintenance mode
  docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --on

  # Remove junk from backups/tmp folder
  sudo rm -rf ${ROOT_DIR}/backups/tmp && sudo mkdir ${ROOT_DIR}/backups/tmp

  echo "Copying files to local from Nextcloud Docker container"
  # Grab files from Docker container in temp folder
  sudo docker cp nextcloudapp:/var/www/html/data ${ROOT_DIR}/backups/tmp
  sudo docker cp nextcloudapp:/var/www/html/themes ${ROOT_DIR}/backups/tmp
  sudo docker cp nextcloudapp:/var/www/html/config ${ROOT_DIR}/backups/tmp

  borg_create

  echo "Removing local copies of data"
  sudo rm -rf ${ROOT_DIR}/backups/tmp && sudo mkdir ${ROOT_DIR}/backups/tmp

  # Enable maintenance mode
  docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --off
}

stage_dokuwiki(){
  BACKUP_SERVICE="dokuwiki"
  BACKUP_DIRECTORIES=("${DOKUWIKI_DATA_DIR}")
  borg_create
}


stage_kanboard(){
  :
}

stage_pico(){
  BACKUP_SERVICE="pico"
  BACKUP_DIRECTORIES=("${PICO_DATA_DIR}")
  borg_create
}

prune_borg(){
  echo $(date)": All Backups - Pruning d14 w4 m6 y* " >> ${ROOT_DIR}/scripts/logs/backups.log
  repos=("nextcloud" "pico")
  for repo in "${repos[@]}"
  do
    sudo BORG_PASSPHRASE=${BORG_PASS} borg prune \
     --stats \
     --keep-daily 7 \
     --keep-weekly 2 \
     --keep-monthly 3 \
     --keep-yearly -1 \
     ${ROOT_DIR}/backups/borg-$repo
  done
  allBackupsSize=$(du -hs ${ROOT_DIR}/backups)
  echo $(date)": Total Backup Size $allBackupsSize" >> ${ROOT_DIR}/scripts/logs/backups.log
}

echo $(date)": === TWIO BACKUP SCRIPT STARTED ===" >> ${ROOT_DIR}/scripts/logs/backups.log
stage_nextcloud
# stage_pico
prune_borg
echo $(date)": === TWIO BACKUP SCRIPT COMPLETE ===" >> ${ROOT_DIR}/scripts/logs/backups.log
