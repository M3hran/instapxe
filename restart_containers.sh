#!/bin/bash

docker-compose stop && docker-compose rm -vf
. ./generate_config.sh
docker-compose up -d
