#!/bin/bash

wget https://instapxe.com/iso/instapxe_agent.tar.gz 
tar -xvzf instapxe_agent.tar.gz -C http/
rm instapxe_agent.tar.gz
cp http/instapxe_agent/squashfs.img http/dsu/LiveOS/

