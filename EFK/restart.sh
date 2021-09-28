#!/bin/bash
docker-compose stop && docker-compose rm -vf
rm -rf /opt/temp/instapxe/EFK/data/elasticsearch/nodes
docker-compose up -d 
