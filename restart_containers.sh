#!/bin/bash

docker compose stop && docker compose rm -vf
rm 2_config/instapxe.conf/bios/pxelinux.cfg/01*
./generate_config.sh
docker compose up -d --force-recreate
