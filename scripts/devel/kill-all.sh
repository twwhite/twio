#!/bin/bash
/twio/scripts/init/stop.sh
docker kill $(docker container ls -q) # Kill all
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
sudo systemctl stop twio.service
sudo systemctl disable twio.service
sudo rm /etc/systemd/system/twio.service
