#!/bin/bash
NUMDRIVES=20

ARG=$@
echo $ARG
for (( i=0; i<$NUMDRIVES; i++))
do 
	if [ -z "$ARG" ]; then
		echo -e "\nDisk $i"
		smartctl -a -d megaraid,$i /dev/sdb | grep 'Serial number\|Non-medium error count'
	else 
		echo -e "\nDisk $i"
		smartctl $ARG -d megaraid,$i /dev/sdb
	fi
done
