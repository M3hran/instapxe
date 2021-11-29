#!/bin/bash
final_report=/home/ubuntu/final_report.csv

[ -f "$final_report" ] || rm $final_report && touch $final_report

for dir in /opt/temp/instapxe/nfs/reports/build/* 
do

	for file in $dir/*
	do	
		#echo $file


	if [[ "$file" =~ (build_summary.csv)$ ]]; then
		sline=$(tail -n 1 "$file")
		echo $sline >> $final_report
	fi

	done

done
