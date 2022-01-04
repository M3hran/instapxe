#!/bin/bash
#outputfile=/opt/temp/instapxe/nfs/reports/notupdated.csv

for dir in /opt/temp/instapxe/nfs/reports/build/* 
do
	for file in $dir/json/*
	do	
		#echo $file


	if [[  "$file" =~ ".json" ]]; then
		#echo "$file"
		if grep "svgtag" $file > /dev/null; then
			echo $file
			sed -i 's/svgtag/svctag/g' $file
			

	
		fi
		
	
	fi


	done

done
