#!/bin/bash

for dir in /opt/temp/instapxe/nfs/reports/build/* 
do

	for file in $dir/*
	do	
		#echo $file


	if [[ "$file" =~ (build_summary.json)$ ]]; then
		echo $file
	        dos2unix $file
	fi
	if [[ "$file" =~ (imaging_log.txt)$ ]]; then
                echo $file
                dos2unix $file
        fi

	done
	for file in $dir/json/*
	do
		if [[ "$file" =~ (osimaging.json)$ ]]; then
                	echo $file
                	dos2unix $file
			
			sed -i 's/\([0-9][0-9]\)\/\([0-9][0-9]\)\/\([0-9][0-9]-\)/\1\/\2\/20\3/g' $file
        		#sed -i 's/\([0-9][0-9]\)\/\([0-9][0-9]\)\/\([0-9]*-\)/\1\/\2\/2021-/g' $file
			#sed -i 's/\([0-9][0-9]\)\/\([0-9]\{4\}\)\/\([0-9][0-9]\)/\1\/21\/\3/g' $file
			#sed -i 's/\([0-9][0-9]\)\/\([0-9][0-9]\)\/\([0-9]*-\)/\1\/\2\/\3/g' $file
		
		fi
	done

done
