#!/bin/bash
final_report=/home/ubuntu/620issue

#[ -f "$final_report" ] || touch $final_report

a=(1BC8H02 443G842 7ZPVZX1 8LWX8Z1 8LXV8Z1 8WKB842 B9HNZ12 B9LQZ12 BBCQZ12 BBFQZ12 BPLVGX1 GSKNQW1 H2FCRW1 H2HBRW1 HGGTGX1 HJJY9Y1 JJFNW12)


for t in ${a[@]}; do
#for dir in /opt/temp/instapxe/nfs/reports/build/$a
#do

	
	cat /opt/temp/instapxe/nfs/reports/build/$t/$t"_hardware_inv.txt" | grep "Memory Device" -A 18 | grep "Size\|Locator" > "$final_report"/"$t"




#	for file in $dir/*
#	do	
#		#echo $file


#	if [[ "$file" =~ (build_summary.csv)$ ]]; then
#		sline=$(tail -n 1 "$file")
#		echo $sline >> $final_report
#	fi

#	done

#done
done
