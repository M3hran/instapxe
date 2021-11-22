#!/bin/bash
#######################
#
#
#  instaPXE sum_helper
#  Copyright @ 2021 instapxe
#  generate and report on the updates process
#
#
#######################


start_time=$SECONDS
MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4,$5}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
MANUFACTURER=$(dmidecode -t 1 | awk '/Manufacturer:/ {print $2,$3}')
MAC=$(ifconfig | grep HWaddr | awk '{print $5}'| head -n1 )
LOCATION=""
WORKDIR="/opt/m3hran"
NFSMOUNT="172.17.1.3:/reports"
DSULOGPATHREMOTE="$WORKDIR/build/$SVCTAG"
LOGFILE="$DSULOGPATHREMOTE/"$SVCTAG"_update_log.txt"
JSONPATH="$DSULOGPATHREMOTE/json"
JSONFILE="$JSONPATH/"$SVCTAG"_updates.json"
UPDATELOGS="$DSULOGPATHREMOTE/updatelogs"
API="http://172.17.1.3:9010/api/device/"
H="Content-Type:application/json" 


export TZ=UTC
ct="$(wget --server-response --spider google.com 2>&1 | grep Date | head -n1 | sed 's/.*, //g')"
nt="$(date -d "$ct" -D "%d %b %Y %T" +'%Y-%m-%d %H:%M:%S')"
date -s "$nt"

export TZ=America/New_York
mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
mkdir -p $DSULOGPATHREMOTE $UPDATELOGS > /dev/null 2>&1
timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}

print_json () {

        if [[ "$1" =~ ^(STARTED)$ ]]; then

                JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"started update\"}"

        elif [[ "$1" =~ ^(REBOOT)$ ]]; then

                elapsed=$(( SECONDS - start_time  ))
                atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"rebooting to apply updates\",\"elapsed\":\"$atime\"}"

        elif [[ "$1" =~ ^(COMPLETED)$ ]]; then

                elapsed=$(( SECONDS - start_time  ))
                atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"


               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"completed updates\",\"elapsed\":\"$atime\"}"

        elif [[ "$1" =~ ^(EXITED)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"error\",\"stage\":\"Update\",\"msg\":\"exited dsu with error\"}"

        fi



        #print event to api
        wget -q --header="$H" --post-data "$JSON_PAYLOAD" $API 
        if [ $? != 0 ];then
                echo "Error: $? - instapxe API unavailable"
                exit 1
        else
                echo "API request successful."
        fi




        [ -d $JSONPATH ] || mkdir -p $JSONPATH

        echo $JSON_PAYLOAD >> $JSONFILE


}

elapsed_time() {

        elapsed=$(( SECONDS - start_time  ))

        eval "echo Elapsed time: $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')"
        echo ""
}
finalize_reports() {
	#look at gatherlogs.sh
	# /tmp/HPSUM
	# /var/hp/log
	[ -e /tmp/HPSUM ] && cp -R /tmp/HPSUM $UPDATELOGS
	[ -e /var/hp/log ] && cp -R /var/hp/log $UPDATELOGS
}

print_sysinfo() {

        echo ""
        echo "    Manufacturer:                 $MANUFACTURER"
        echo "    System Model:                 $MODEL"
        echo "    SVCTAG/Serial:                $SVCTAG"
        echo ""



}
(
case "$1" in

	*start*)
		
			
		cat /opt/instapxe/DISCLAIMER
		echo " "
		echo " "
		echo "Automated System Update Initializing..."
		echo "Update started at: " `timestamp` && print_json "STARTED"
	   	print_sysinfo
		;;


	*end*)
		echo ""
                echo "Update completed at: " `timestamp` && print_json "COMPLETED"
		finalize_reports
		elapsed_time
		echo "DONE. NO MORE APPLICABLE UPDATES."
                echo ""
               

	
		
		;;
esac
) 2>&1 | tee -a $LOGFILE
exit 0
