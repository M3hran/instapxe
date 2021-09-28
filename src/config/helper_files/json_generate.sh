#1/bin/bash

REPORTS_DIR=/opt/temp/instapxe/nfs/reports/build

print_json() {

	P=$@
	[ -d $d/json ] || mkdir -p $d/json
	
	echo $P >> $d/json/"$SVCTAG"_updates.json 

}

parse_data() {
         
	#echo ${@:2}
	VAL=$( awk '{for (i = 0; ++i <= NF;) print $i}' <<< ${@:2})
	
        TIME=""
	if [[ "$1" =~ ^(ELAPSED)$ ]]; then
		e=""
		for j in $VAL;
		do
			
			e="${e} ${j}"
			if [[ "$j" =~ ^(sec)$ ]]; then
				
				JSON_PAYLOAD="{\"elapsed_time\":\"$e\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"elapsed time\"}"
				e=""
				[ -z "$JSON_PAYLOAD" ] || print_json $JSON_PAYLOAD
			fi
		done

	else

        for i in $VAL
        do
           	if ! [[ "$i" =~ ^(AM|PM)$ ]]; then
              	
			TIME="$i"
           
		elif [[ "$i" =~ ^(AM|PM)$ ]]; then

           	
			TIME="${TIME} ${i}"
	   	
			if [[ "$1" =~ ^(STARTED)$ ]]; then
           	
				JSON_PAYLOAD="{\"time\":\"$TIME\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"started update\"}"
		
			elif [[ "$1" =~ ^(REBOOT)$ ]]; then

				JSON_PAYLOAD="{\"time\":\"$TIME\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"rebooting to apply updates\"}"

			elif [[ "$1" =~ ^(COMPLETED)$ ]]; then

                                JSON_PAYLOAD="{\"time\":\"$TIME\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"completed updates\"}"
			fi

	   
			[ -z "$JSON_PAYLOAD" ] || print_json $JSON_PAYLOAD 
           		TIME=""
 
 	  	 fi

        done

	fi

}


for d in $REPORTS_DIR/*
do
	SVCTAG=$( echo $d | awk -F "/" '{print $8}')
	UPDATE_LOG="$d"/"$SVCTAG"_update_log.txt
        JSON_PAYLOAD=""	

	if [ -f $UPDATE_LOG ]; then
		MODEL=$( grep "^Model:" $UPDATE_LOG | head -1 | awk '{print $2}' )

		STARTED=$( grep "^Update started" $UPDATE_LOG | awk '{print $4, $5, $6}' )
		[ -z "$STARTED " ] || parse_data "STARTED" $STARTED
        
                ELAPSED=$( grep "^Elapsed time:" $UPDATE_LOG | awk '{print $3, $4, $5, $6, $7, $8, $9, $10}' )
                [ -z "$ELAPSED " ] || parse_data "ELAPSED" $ELAPSED


		REBOOTING=$( grep "^Rebooting to apply updates at:" $UPDATE_LOG | awk '{print $6, $7}' )
		[ -z "$REBOOTING" ] || parse_data "REBOOT" $REBOOTING
		

		COMPLETED=$( grep "^Update completed at:" $UPDATE_LOG | awk '{print $4, $5}' )
                [ -z "$COMPLETED" ] || parse_data "COMPLETED" $COMPLETED


	fi
	

done
