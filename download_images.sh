#!/bin/bash
instapxe_dir="/opt/instapxe/"

echo "checking for images to download.."

# instapxe agent
if [ ! -f $instapxe_dir/http/dsu/LiveOS/squashfs.img ] || [ ! -f $instapxe_dir/http/instapxe_agent/squashfs.img ] 
then
	echo "Downloading... instapxe_agent img"
	cd /tmp && wget https://instapxe.com/images/instapxe_agent.tar.gz 
	tar -xvzf instapxe_agent.tar.gz -C $instapxe_dir/http/
	rm instapxe_agent.tar.gz
	cp $instapxe_dir/http/instapxe_agent/squashfs.img http/dsu/LiveOS/
else
	echo "instapxe_agent exists... Skipping!"
fi

# 3fold zero os
if [ ! -f $instapxe_dir/http/3Fold_Zero-OS/ipxe-prod.lkrn ]
then
	echo "Downloading.. 3Fold Zero-OS img"
	mkdir -p $instapxe_dir/http/3Fold_Zero-OS
	cd /tmp && wget https://instapxe.com/images/ipxe-prod.lkrn
	cp /tmp/ipxe-prod.lkrn $instapxe_dir/http/3Fold_Zero-OS/
else
	echo "3Fold-Zero OS exists... Skipping!"
fi

# DBAN
if [ ! -f $instapxe_dir/http/dban/DBAN.BZI ]
then
        echo "Downloading.. DBAN img"
        mkdir -p $instapxe_dir/http/dban
        cd /tmp && wget https://instapxe.com/images/DBAN.BZI
        cp /tmp/DBAN.BZI $instapxe_dir/http/dban/
else
        echo "DBAN exists... Skipping!"
fi

