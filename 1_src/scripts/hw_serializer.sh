#!/bin/bash

JSON_PAYLOAD={}
get_details() {


        while IFS= read -r line
        do
		
		if [[ "$line" =~ "Handle"  ]]; then
			echo "$line"
			echo "\n"
		fi

	done <<< "${@:1}"

}


parse_data() {

	BI=$( awk -v RS= '/*/' "${@:1}" )
		echo "$line"
	#echo "$TYPE"
	get_details "$BI"
	


	#JSON_PAYLOAD=$( jq -n \ 
	#	  --arg bn "$BUCKET_NAME" \
        #          --arg on "$OBJECT_NAME" \
        #          --arg tl "$TARGET_LOCATION" \
        #          '{bucketname: $bn, objectname: $on, targetlocation: $tl}' )

	






	#echo ${@:1}
	#VAL=$( awk '{for (i = 0; ++i <= NF;) print $i}' <<< ${@:1})
	#echo $VAL
}

parse_data $1
