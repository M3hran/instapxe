#!/bin/bash
outputfile=/opt/temp/instapxe/nfs/reports/notupdated.csv

for dir in /opt/temp/instapxe/nfs/reports/build/* 
do
	os=0
        update=0
	for file in $dir/*
	do	
		#echo $file


	if [[  "$file" =~ (firmware_inv.xml)$ ]]; then
		update=1
	fi
	if [[  "$file" =~ (build_summary.csv)$ ]]; then
                os=1
        fi


	done
	if [ $update -eq 0 ]; then
		if [ $os -eq 1  ]; then
			echo -n "$(echo $dir | cut -d "/" -f8)", >> $outputfile
		fi

	fi

done
