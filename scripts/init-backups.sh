#!/bin/bash
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
echo ${BORG_PASS}
echo "Variables loaded!"

script_set_root_dir(){

  echo "Setting up run-backups script..."
  cp ${ROOT_DIR}/scripts/run-backups.sh.example ${ROOT_DIR}/scripts/run-backups.sh

  if grep -Gq "ROOTDIRPLACEHOLDER" "${ROOT_DIR}/scripts/run-backups.sh"
  then
    echo "Setting absolute root_dir reference in Run Backups script in order for cron to load .env properly"
    sudo sed -i "s|ROOTDIRPLACEHOLDER|${ROOT_DIR}|" ${ROOT_DIR}/scripts/run-backups.sh

  fi
}

get_available_space() {
  str_available_space=$(df -h "."  | awk 'NR==2{print $4}')
  echo "Available disk space: "$str_available_space
}

install_borg() {
  echo "Installing Borg if not already installed..."
  hash borg 2>/dev/null || { sudo apt install borgbackup; :;}
}

init_borg_repo(){
  repos=("nextcloud" "pico" "kanboard" "dokuwiki" "homer")
  numRepos=${#repos[@]}
  paddingInMB=2048 #Pad the backup with 2G distributed across each borg repo to ensure filesystem never gets full enough to crash Borg.
  paddingPerRepo=$(($paddingInMB/$numRepos))'M'
  for repo in "${repos[@]}"
  do
    echo "Initializing local Borg repository in "$ROOT_DIR/backups/borg-$repo""
    echo $(date)": Initializing local Borg repository in "$ROOT_DIR/backups/borg-$repo"" >> ${ROOT_DIR}/scripts/logs/backups.log
    sudo BORG_PASSPHRASE=${BORG_PASS} borg init --encryption=repokey $ROOT_DIR/backups/borg-$repo >/dev/null
    sudo borg config $ROOT_DIR/backups/borg-$repo additional_free_space $paddingPerRepo
  done
}

create_backup_service(){
  crontab -l > mycron
  # Run twice daily - 01 AM and 01 PM
  # echo "00 01,13 * * * /twio/scripts/run-backups.sh" >> mycron

  # TODO: Fix cron time
  echo "*/1 * * * * /twio/scripts/run-backups.sh >/dev/null 2>&1" >> mycron

  sudo crontab mycron
  rm mycron
}

script_set_root_dir
get_available_space
install_borg
init_borg_repo
# create_backup_service
