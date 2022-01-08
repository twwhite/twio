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
    sed -i "s|ROOTDIRPLACEHOLDER|${ROOT_DIR}|" ${ROOT_DIR}/scripts/run-backups.sh

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
    BORG_PASSPHRASE=${BORG_PASS} borg init --encryption=repokey $ROOT_DIR/backups/borg-$repo >/dev/null
    borg config $ROOT_DIR/backups/borg-$repo additional_free_space $paddingPerRepo
  done
}


rclone_config(){

  rcloneFinalDestination=""
  echo
  echo "====== RCLONE CONFIG ======"
  echo
  rclone config
  echo
  select_rclone_remote
}

select_rclone_remote(){
  echo
  echo "====== SELECT RCLONE REMOTE & DESTINATION FOR USE WITH TWIO BACKUPS ======"
  echo
  ## Setup & Get Rclone remote
  z=1
  remotes=( $(rclone listremotes) )
  for x in "${remotes[@]}"
  do
    echo "[$z] $x"
    z=$(($z+1))
  done
  echo "[$z] Return to Rclone config"
  z=$(($z+1))
  echo "[$z] Skip Rclone remote backup deployment and continue"
  echo
  while :
  do
    read -e -p "Select remote from above: " s
    if [[ $s -gt 0 && $s -lt ${#remotes[@]}+3 ]]; then :; else echo "Invalid selection. Please try again." && continue; fi
    if [[ $s -eq $z-1 ]]; then break&&rclone_config; fi
    if [[ $s -eq $z ]]; then echo "Skipped Rclone Setup"&&break; fi
    echo
    echo "Rclone remote selected: " ${remotes[$s-1]}
    echo "Loading directories..."
    rcloneRemoteSelection=${remotes[$s-1]}
    break
  done
  select_rclone_destination
}

select_rclone_destination(){

  z=1
  buckets=( $(rclone lsf $rcloneRemoteSelection --dirs-only ))
  for x in "${buckets[@]}"
  do
    echo "[$z] $x"
    z=$(($z+1))
  done
  if [[ $z -eq 1 ]]; then clear&&echo "error connecting to remote; check config."&&select_rclone_remote; fi
  echo "[$z] Return to Rclone config"
  z=$(($z+1))
  echo "[$z] Skip Rclone remote backup deployment and continue"
  echo
  while :
  do
    read -e -p "Select destination directory from above: " b
    if [[ $b -gt 0 && $b -lt ${#buckets[@]}+3 ]]; then :; else echo "Invalid selection. Please try again." && continue; fi
    if [[ $b -eq $z-1 ]]; then rclone_config; fi
    if [[ "$b" == "$z" ]]; then echo "Skipped Rclone Setup"&&break; fi
    echo
    # echo "Destination directory selected: " ${buckets[$b-1]}
    rcloneDestinationSelection=${buckets[$b-1]}
    rcloneFinalDestination=$rcloneRemoteSelection$rcloneDestinationSelection
    echo "Rclone backup destination confirmed: "$rcloneFinalDestination
    if grep -Gq "RCLONE_REMOTE_NAME" "$FILE"
    then
      read -e -p "RCLONE destination exists in .env file, overwrite (y/n)? "  c
      if ! [ $"$c" == "y" ]
      then
        continue
      else
        sed -i "s/RCLONE_REMOTE_NAME.*//g" "$FILE"
        sed -ir '/^\s*$/d' "$FILE"
      fi
      echo "RCLONE_REMOTE_NAME=$rcloneFinalDestination">>.env
    fi
    break
  done
}

setup_rclone_remote(){
  read -e -p "Setup Rclone remote backup deployment (Y/n)? " x
  if [ $"$x" == "y" ]
  then
    clear
    rclone_config
  else
    noRemote=1
  fi
}

create_backup_service(){
  crontab -l > mycron

  # Backup every hour

  echo "0 * * * /twio/scripts/run-backups.sh >/dev/null 2>&1" >> mycron

  crontab mycron
  rm mycron
}

script_set_root_dir
get_available_space
install_borg
init_borg_repo
setup_rclone_remote
create_backup_service
echo "Backup initializing complete."
