#!/bin/bash
import_env(){
  # Import .env vars -> Carries over to docker-compose.yml
  FILE=./.env

  if [ -f $FILE ]; then
    echo "Loading variables from $FILE"
    set -o allexport
    source $FILE
    set +o allexport
  else
    echo "Error: Please setup a .env file according to the README.md"
    exit 1
  fi
}

get_running_docker_compose_services(){
  running_services=$(docker-compose ps --services)
  arr_running_services=($(echo $running_services | tr " " "\n"))
}

select_files(){
  find ./ -printf "%f\n"
}

main_menu(){

  echo
  echo "Note: Recovery files must be placed in a subdirectory within the $PWD/recovery directory corresponding to the service name"
  echo "Example: recovery/pico/{RECOVERY_FILES}*"
  echo
  echo "Active Services:"

  x=1
  for i in ${arr_running_services[@]}; do echo "[$x] $i" && x=$(($x+1)); done

  echo
  while :
  do
    read -ep "Please select a service from above to begin recovery: " selection
    if [[ $selection -gt 0 && $selection -lt ${#arr_running_services[@]}+1 ]]; then break; else echo "Invalid selection. Please try again."; fi
  done
  cmd=("restore_"${arr_running_services[$selection-1]})


  echo "Entering recovery for "${arr_running_services[$selection-1]}
  clear
  "${cmd[@]}" || error_not_implemented
}


error_not_implemented(){
  echo
  clear
  echo "============================================================================="
  echo "=== Error: Recovery function not implemented for this service yet. Sorry! ==="
  echo "============================================================================="
  main_menu
}

check_for_backups_in_dir(){
  if [ -z "$(ls -A ./recovery)" ]
  then
    echo "Error: Please move files/directories for recovery to $PWD/recovery"
    echo "Exiting recovery."
    exit 1
  else
    :
  fi
}

restore_pico(){
  :
}

restore_homer(){
  :
}

#
# restore_kanboard(){
#   :
# }

restore_dokuwiki(){
  :
}

restore_nextcloud(){

  echo "Nextcloud Recovery Mode"
  echo "========================"
  echo
  echo "Step 1/2: Database recovery"


  echo "Step 2/2: File recovery"

  # Enable maintenance mode
  docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --on

  docker exec --user www-data -ti nextcloud php occ files:scan --all

  # Enable maintenance mode
  docker exec -ti --user www-data nextcloudapp php occ maintenance:mode --off
}

restore_freshrss(){
  :
}

clear
get_running_docker_compose_services
import_env
main_menu
# check_for_backups_in_dir

# restore_nextcloud
