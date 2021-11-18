#!/bin/bash
final_report=/opt/temp/instapxe/nfs/reports/final_report.csv

[ -f "$final_report" ] || touch $final_report

for dir in /opt/temp/instapxe/nfs/reports/build/* 
do

	for file in $dir/health_checks/*
	do	
		#echo $file


	if [[ "$file" == *1_bios_errors.txt ]]; then
		grep -i 'fail\|error\|lost' $file >> /tmp/errors.txt
		if [ -f /tmp/errors.txt ]; then

			IFS=$'\n' read -d '' -r -a lines < /tmp/errors.txt
			for k in "${lines[@]}"
		        do

				echo "$k"
				E_DEVICE=$(echo "$k" | awk -F\| '{print $4}')
				E_DESC=$(echo "$k" | awk -F \| '{print $5}' )
                		echo "$E_DEVICE $E_DESC"


        		done

		

		fi

		#echo $a
		#sline=$(tail -n 1 "$file")
		#echo $sline >> $final_report
	fi

	done

done
