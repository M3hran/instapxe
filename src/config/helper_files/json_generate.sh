#1/bin/bash

REPORTS_DIR=/opt/temp/instapxe/nfs/reports/build


for d in $REPORTS_DIR/*
do
	SVCTAG=$( echo $d | awk -F "/" '{print $8}')
	UPDATE_LOG="$d"/"$SVCTAG"_update_log.txt
        JSON_PAYLOAD=""	

	if [ -f $UPDATE_LOG ]; then
		MODEL=$( grep "^Model:" $UPDATE_LOG | head -1 | awk '{print $2}' )
		S_UPDATE_TIMES=$( grep "^Update started" $UPDATE_LOG | awk '{print $4, $5, $6}' )
		TIME=""
		J=""
		S2=$( awk '{for (i = 0; ++i <= NF;) print $i}' <<< $S_UPDATE_TIMES)

                for i in $S2
		do
			if ! [[ "$i" == "AM"||"PM" ]]; then
                                TIME=$i
                        else
                                TIME="${TIME} ${i}"
                                JSON_PAYLOAD="{\"time\":\"$TIME\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"msg\":\"Update started\"}"
                 		echo $JSON_PAYLOAD       
			fi
                done

		#JSON_PAYLOAD="{\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\"}"
		#echo $JSON_PAYLOAD

	fi
	

done
