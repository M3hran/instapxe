#!/bin/bash
####################################################################
#
# 2021 instapxe (c) copyright
# https://instapxe.com/eula
# instapxe_agent.sh
# maintained by: m3hran
#
####################################################################


printf "\033c"

start_time=$SECONDS
MAC=$(cat /sys/class/net/*/address | head -n 1)
NTPSERVER="192.168.1.90"
NFSMOUNT="192.168.1.90:/reports"
WORKDIR="/opt/instapxe"
BITDIR="$WORKDIR/burnintest"
MANUFACTURER=$(dmidecode -t 1 | awk '/Manufacturer:/ {$1=""; print substr($0,2)}')
#MANUFACTURER=$(dmidecode -t 1 | awk '/Manufacturer:/ {print $2,$3}')
MAKE=$(echo "$MANUFACTURER" | sed -e 's:^Dell$:Dell:' -e 's:^HP$:HP:' -e 's:^VMware$:VMware:')

MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {$1=$2=""; print substr($0,3)}')
#MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4,$5}')
CHASSIS_TYPE=$(dmidecode -t 3 | awk '/Type:/ {$1=""; print substr($0,2)}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
GENERATION="$(dmidecode -t 1 | awk '/Product Name:/ {print substr($4,3,1)}')"
INSTAPXE_LOGPATH_REMOTE="$WORKDIR/build/$SVCTAG"
LOGFILE="$INSTAPXE_LOGPATH_REMOTE/"$SVCTAG"_hw_scan_log.txt"
IPMILOGPATH="$INSTAPXE_LOGPATH_REMOTE/health_checks"
#IPMILOGPATH_HWSCAN="$IPMILOGPATH/hw_scan"
HDDLOGPATH="$INSTAPXE_LOGPATH_REMOTE/controller_drives"
SMARTFILE="$HDDLOGPATH/"$SVCTAG"_smartlog.txt"
JSONPATH="$INSTAPXE_LOGPATH_REMOTE/json"
JSONFILE="$JSONPATH/"$SVCTAG"_updates.json"
LOCATION=""
API="http://172.17.1.3:9010/api/device/"
H='-H "Content-Type: application/json" -H "Accept: application/json"'
EXITCODE=0
racadm="/opt/dell/srvadmin/sbin/racadm"

yum install -y lshw > /dev/null 2>&1

##ANSI COLOR CODES
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White


mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
mkdir -p $INSTAPXE_LOGPATH_REMOTE $IPMILOGPATH $JSONPATH $HDDLOGPATH $SMARTLOGPATH > /dev/null 2>&1
touch $LOGFILE $JSONFILE $SMARTFILE




timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}

print_reports_location () {

	echo ""
	echo "		Access reports at:"
        echo ""	
	echo " 		http://$NTPSERVER/reports/hw_scan/$SVCTAG"
	echo ""
}
print_json () {

	if [[ "$1" =~ ^(STARTED)$ ]]; then

                JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"started hardware scan.\"}"

	elif [[ "$1" =~ ^(REBOOT)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"rebooting to apply updates\"}"

        elif [[ "$1" =~ ^(COMPLETED)$ ]]; then
		elapsed=$(( SECONDS - start_time  ))
		atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"

		JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"completed hardware scan\",\"elapsed\":\"$atime\"}"

	elif [[ "$1" =~ ^(EXITED)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"error\",\"stage\":\"hw_scan\",\"msg\":\"exited hardware scan with error\"}"
	
 	elif [[ "$1" =~ ^(ERROR)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"$MANUFACTURER\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"error\",\"stage\":\"hw_scan\",\"msg\":\"$2 $3\"}"       
        fi


	#print event to api
        curl -sk "$H" -X POST --data "$JSON_PAYLOAD" $API > /dev/null 
        if [ $? != 0 ];then
        	echo "Error: $? - instapxe API unavailable"
                exit 1
        else
                echo "API request successful."
        fi

	#print event to logfile
	[ -d $JSONPATH ] || mkdir -p $JSONPATH
        echo $JSON_PAYLOAD >> $JSONFILE


}

service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

elapsed_time() {

	elapsed=$(( SECONDS - start_time  ))

	eval "echo Elapsed time: $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')"
	echo ""
}



gather_dmidecode() {
	#generate HW inventory report
	echo -ne "Gathering HW inventory data... "
 	dmidecode -q > $INSTAPXE_LOGPATH_REMOTE/"$SVCTAG"_hardware_inv.txt && sed -i '/dmidecode.*/d' $INSTAPXE_LOGPATH_REMOTE/"$SVCTAG"_hardware_inv.txt

	lshw -html > $INSTAPXE_LOGPATH_REMOTE/"$SVCTAG"_Hardware_Inventory.html
	lspci -v > $INSTAPXE_LOGPATH_REMOTE/"$SVCTAG"_PCI_Inventory.txt
	echo -ne "done."
        echo -ne "\n"
}


clear_eventlogs(){


if [ -c /dev/ipmi0 ] || [ -c /dev/ipmi/0 ] || [ -c /dev/ipmidev/0 ] ; then
	
	
	ipmitool sel clear
	if [ $? -ne 0 ]; then
	      	echo "Error: unable to clear BMC logs, corrupt cache, try rebooting!"
		print_json "ERROR" "unable to clear BMC logs, corrupt cache, try rebooting!"
		EXITCODE=1
	fi
	

fi

}

gather_sensor_data() {
	
	#local STATE=$1
        #generat IPMI info report
	echo -ne "Performing health checks on sensors... "

	if [ -c /dev/ipmi0 ] || [ -c /dev/ipmi/0 ] || [ -c /dev/ipmidev/0 ] ; then
	ipmitool chassis selftest > $IPMILOGPATH/"$SVCTAG"_3_selftest_results.txt
	ipmitool sdr type 0x01 > "$IPMILOGPATH"/"$SVCTAG"_temp.txt
        ipmitool sdr type 0x02 > "$IPMILOGPATH"/"$SVCTAG"_voltage.txt
        ipmitool sdr type 0x03 > "$IPMILOGPATH"/"$SVCTAG"_current.txt
        ipmitool sdr type 0x04 > "$IPMILOGPATH"/"$SVCTAG"_fan.txt
        ipmitool sdr type 0x05 > "$IPMILOGPATH"/"$SVCTAG"_physical_security.txt
        ipmitool sdr type 0x06 > "$IPMILOGPATH"/"$SVCTAG"_platform_security.txt
        ipmitool sdr type 0x07 > "$IPMILOGPATH"/"$SVCTAG"_processor.txt
        ipmitool sdr type 0x08 > "$IPMILOGPATH"/"$SVCTAG"_power_supply.txt
        ipmitool sdr type 0x09 > "$IPMILOGPATH"/"$SVCTAG"_power_unit.txt
        ipmitool sdr type 0x0a > "$IPMILOGPATH"/"$SVCTAG"_cooling_device.txt
        ipmitool sdr type 0x0b > "$IPMILOGPATH"/"$SVCTAG"_other.txt
        ipmitool sdr type 0x0c > "$IPMILOGPATH"/"$SVCTAG"_memory.txt
        ipmitool sdr type 0x0d > "$IPMILOGPATH"/"$SVCTAG"_drive_bay.txt
        ipmitool sdr type 0x0e > "$IPMILOGPATH"/"$SVCTAG"_post_memory_resize.txt
        ipmitool sdr type 0x0f > "$IPMILOGPATH"/"$SVCTAG"_firmwares.txt
        ipmitool sdr type 0x10 > "$IPMILOGPATH"/"$SVCTAG"_event_logging.txt
        ipmitool sdr type 0x11 > "$IPMILOGPATH"/"$SVCTAG"_watchdog1.txt
        ipmitool sdr type 0x12 > "$IPMILOGPATH"/"$SVCTAG"_system_event.txt
        ipmitool sdr type 0x13 > "$IPMILOGPATH"/"$SVCTAG"_critical_interrupt.txt
        ipmitool sdr type 0x14 > "$IPMILOGPATH"/"$SVCTAG"_button.txt
        ipmitool sdr type 0x15 > "$IPMILOGPATH"/"$SVCTAG"_board.txt
        ipmitool sdr type 0x16 > "$IPMILOGPATH"/"$SVCTAG"_microcontroller.txt
        ipmitool sdr type 0x17 > "$IPMILOGPATH"/"$SVCTAG"_add_in_card.txt
        ipmitool sdr type 0x18 > "$IPMILOGPATH"/"$SVCTAG"_chassis.txt
        ipmitool sdr type 0x19 > "$IPMILOGPATH"/"$SVCTAG"_chip_set.txt
        ipmitool sdr type 0x1a > "$IPMILOGPATH"/"$SVCTAG"_other_fru.txt
        ipmitool sdr type 0x1b > "$IPMILOGPATH"/"$SVCTAG"_cable.txt
        ipmitool sdr type 0x1c > "$IPMILOGPATH"/"$SVCTAG"_terminator.txt
        ipmitool sdr type 0x1d > "$IPMILOGPATH"/"$SVCTAG"_system_boot_init.txt
        ipmitool sdr type 0x1e > "$IPMILOGPATH"/"$SVCTAG"_boot_error.txt
        ipmitool sdr type 0x1f > "$IPMILOGPATH"/"$SVCTAG"_os_boot.txt
        ipmitool sdr type 0x20 > "$IPMILOGPATH"/"$SVCTAG"_os_critical_stop.txt
        ipmitool sdr type 0x21 > "$IPMILOGPATH"/"$SVCTAG"_slot_connector.txt
        ipmitool sdr type 0x22 > "$IPMILOGPATH"/"$SVCTAG"_acpi_power_status.txt
        ipmitool sdr type 0x23 > "$IPMILOGPATH"/"$SVCTAG"_watchdog2.txt
        ipmitool sdr type 0x24 > "$IPMILOGPATH"/"$SVCTAG"_platform_alert.txt
        ipmitool sdr type 0x25 > "$IPMILOGPATH"/"$SVCTAG"_entity_presence.txt
        ipmitool sdr type 0x26 > "$IPMILOGPATH"/"$SVCTAG"_monitor_asic.txt
        ipmitool sdr type 0x27 > "$IPMILOGPATH"/"$SVCTAG"_lan.txt
        ipmitool sdr type 0x28 > "$IPMILOGPATH"/"$SVCTAG"_management_subsystem_health.txt
        ipmitool sdr type 0x29 > "$IPMILOGPATH"/"$SVCTAG"_battery.txt
        ipmitool sdr type 0x2a > "$IPMILOGPATH"/"$SVCTAG"_session_audit.txt
        ipmitool sdr type 0x2b > "$IPMILOGPATH"/"$SVCTAG"_version_change.txt
        ipmitool sdr type 0x2c > "$IPMILOGPATH"/"$SVCTAG"_fru_state.txt
        ipmitool sdr list > $IPMILOGPATH/"$SVCTAG"_2_sensors_health_summary.txt
   	ipmitool sel list > $IPMILOGPATH/"$SVCTAG"_1_bios_errors.txt
	#error out if there is no bmc
	else
		#if [[ "$CHASSIS_TYPE" -ne "Desktop" ]]; then

			echo "Error: IPMI controller not found"
			EXITCODE=1
		#fi
	fi
	echo -ne "done."
        echo -ne "\n"

}

gather_mega_data(){
		
	megacli=/opt/MegaRAID/MegaCli/MegaCli64
        echo -ne "Gathering MegaRAID Controller & Disk data... "
        $megacli -ShowSummary -aALL > "$HDDLOGPATH"/"$SVCTAG"_megacli_summary.txt
        $megacli -PDList -aALL > "$HDDLOGPATH"/"$SVCTAG"_physicaldisk_list.txt
        $megacli -LDPDInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_physicaldisk_details.txt
        $megacli -LDInfo -Lall -aALL > "$HDDLOGPATH"/"$SVCTAG"_virtualdrive_info.txt
        $megacli -EncInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_enclosure_info.txt
        $megacli -AdpAllInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_controller_info.txt
        $megacli -CfgDsply -aALL > "$HDDLOGPATH"/"$SVCTAG"_controller_config_info.txt
        $megacli -AdpBbuCmd -aALL > "$HDDLOGPATH"/"$SVCTAG"_bbu_info.txt
        $megacli -AdpPR -Info -aALL > "$HDDLOGPATH"/"$SVCTAG"_patrolread_state.txt
	echo -ne "done."
	echo -ne "\n"

}
gather_smart_data() {

	declare -A address
	CARG=""
	echo -ne "Gathering S.M.A.R.T. Disk data... "
	cat /DISCLAIMER > "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
    	cat /DISCLAIMER > $SMARTFILE 
	#cat /DISCLAIMER >> "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
	#get raid contoller info
	lspci | egrep -i 'raid' >> $SMARTFILE
        cat /proc/scsi/scsi >> $SMARTFILE
	#get disks devices
	smartctl --scan | awk '{print $3}' >> $SMARTFILE
	ls -la /dev/sg* | awk '{print $10}' >> $SMARTFILE


	i=0
	j=0
	
	IFS=$'\n' read -d '' -r -a lines < $SMARTFILE 

	#gather SMART disk data for all drives
	for k in "${lines[@]}"
	do
		
		if [[ $k =~ /dev/sd* || $k =~ /dev/hd* || $k =~ /dev/sg* || $k =~ megaraid* ]]; then

			case $MAKE in

        			*"Dell"*)
					if [[ $k =~ megaraid* ]]; then
						cat /DISCLAIMER > "$HDDLOGPATH"/"$SVCTAG"_drive_"$j".txt	
						smartctl -a -d "$k" /dev/sg0 >> "$HDDLOGPATH"/"$SVCTAG"_drive_"$j".txt
						
						#get health status 
						echo -e "\nDisk $j" >> "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
                				smartctl -a -d $k /dev/sg0 | grep 'Serial number\|User Capacity\|SMART Health Status\|Non-medium error count\|Serial Number\|SMART overall-health\|Power_On_Hours\|Media_Wearout_Indicator' >>  "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
					fi
                			;;
        			*"HP"*)
					
					CARG="cciss"
					cat /DISCLAIMER > "$HDDLOGPATH"/"$SVCTAG"_drive_"$j".txt
					smartctl -a -d "$CARG","$j" "$k" >> "$HDDLOGPATH"/"$SVCTAG"_drive_"$j".txt

					#get health status
                                        echo -e "\nDisk $j" >> "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
                                        smartctl -a -d "$CARG","$j" "$k" | grep 'Serial number\|User Capacity\|SMART Health Status\|Non-medium error count\|Serial Number\|SMART overall-health\|Power_On_Hours\|Media_Wearout_Indicator'  >>  "$HDDLOGPATH"/"$SVCTAG"_SMART_health_status.txt
                			;;

        			*)

                			echo "ERROR: SMART disk scan could not detect manufacturer - $MAKE"
					break
                			EXITCODE=1
                			;;
			esac

			j=$(($j + 1))
		fi
	done
	echo -ne "done."
	echo -ne "\n"

}
get_cluster_location() {

	echo -ne "Detecting cluster location..."
	interface=$( ifconfig | head -n1 | cut -d ":" -f 1)
	value=$( tcpdump -q -nn -v -i $interface -s 500 -c 1 'ether[20:2]==0x2000' 2> /dev/null |  grep -i "Device-ID\|Port-ID" | cut -d "'" -f 2,4 )
	RACK=$( echo $value | cut -c 2)
	RU=$( echo $value |  awk -F '/' '{print $2}' )
	LOCATION="Rack$RACK-U$RU"
	echo -ne "done."
        echo -ne "\n"
}

reset_idrac() {
	
	echo -ne "Resetting iDRAC... "
	$racadm "racresetcfg -rc"
	echo -ne "done."
	echo -ne "\n"

}

change_bios_mode(){
        local mode=$1
	string="jobqueue create BIOS.Setup.1-1"
        echo "Setting Boot mode to..$mode"
        $racadm set bios.BiosBootSettings.BootMode $mode
        $racadm $string

}


shutdowng() {

       #change_bios_mode Uefi
       echo "system shutting down!"
       sleep 5
       shutdown -h now
}
restartg() {

       echo "system restarting!"
       sleep 5
       shutdown -r now

}
print_reports_location () {

        echo ""
        echo "    Access reports at:"
        echo ""
        echo "    http://$NTPSERVER/reports/build/$SVCTAG"
        echo ""
}

print_sysinfo() {
	
	echo ""
	echo -e "    Manufacturer: 		$MANUFACTURER"
	echo -e "    System Model: 		$MODEL"
	echo -e "    SVCTAG/Serial: 		$SVCTAG"
	echo -e "    Cluster Location: 		$LOCATION"
	echo ""

}

error_check() {

	# Missing Serial number check
	if [[ "$SVCTAG" == "" ]]; then
		echo "Following errors detected:"
		print_json "ERROR: missing SVCTAG/SERIAL number"
                EXITCODE=1
	fi
	#only for ipmi enabled devices	
	if [ -c /dev/ipmi0 ] || [ -c /dev/ipmi/0 ] || [ -c /dev/ipmidev/0 ]; then
	
		# check reported BIOS Error check
 		BIOSERRORS="$IPMILOGPATH/"$SVCTAG"_1_bios_errors.txt"
        	grep -i 'fail\|error\|corrupt\|redundancy' $BIOSERRORS | tail -n 10 > "$IPMILOGPATH/"$SVCTAG"_parsed_errors.txt"

		# check reported device errors	- disabled b/c it nvram didn't clear corrupt data/errors
		#for file in "$IPMILOGPATH"
		#do

		#grep -hid skip 'error\|corrupt' "$IPMILOGPATH"/*| awk -F\| '$5 ~ " " {print $1":"$5}' > "$IPMILOGPATH/"$SVCTAG"_parsed_errors.txt"
		#done

		if [ -s "$IPMILOGPATH/"$SVCTAG"_parsed_errors.txt" ]; then

			echo "Following errors detected:"

	        	IFS=$'\n' read -d '' -r -a lines < "$IPMILOGPATH/"$SVCTAG"_parsed_errors.txt"

        
        		for k in "${lines[@]}"
			do

			 	E_DEVICE=$(echo "$k" | awk -F\: '{print $1}')
  	                	E_DESC=$(echo "$k" | awk -F \: '{print $2}' )
			 	#skip powersupply errors mostly loose cables
			 	if [[ "$E_DEVICE" == *"Power Supply"* ]]; then

			 		echo "		$E_DEVICE   $E_DESC  skipping..false positive?"
				else

			 		echo "		$E_DEVICE   $E_DESC"
			 		print_json "ERROR" "$E_DEVICE" "$E_DESC"
					EXITCODE=1
				fi
			done


		fi
		# check Self test results for errors
		SELFTEST="$IPMILOGPATH/"$SVCTAG"_3_selftest_results.txt"
		grep -i 'fail\|error\|corrupt\|redundancy' $SELFTEST > "$IPMILOGPATH/"$SVCTAG"_parsed_selfcheck_errors.txt"
		if [ -s "$IPMILOGPATH/"$SVCTAG"_parsed_selfcheck_errors.txt" ]; then

	                echo "Following self-check errors detected:"


	                IFS=$'\n' read -d '' -r -a lines < "$IPMILOGPATH/"$SVCTAG"_parsed_selfcheck_errors.txt"


	                for k in "${lines[@]}"
	                do

	                         E_DESC=$(echo "$k")
	                         echo "         $E_DESC"
	                         print_json "ERROR" "$E_DESC" 
	                done

        	EXITCODE=1
        	fi
	fi
}
check_make_model() {
	
	if [[ -z $(echo "$MANUFACTURER") ]]; then
	        #echo "manufacturer empty"
		if [ -z $(echo "$MODEL") ]; then
			if [ -z $(echo "$SVCTAG") ]; then
				echo "Error: No System info for Make,Model,and Serial."
				EXITCODE=1
			else 
				if [ ${#SVCTAG} -eq 7 ]; then
					#REFACTOR: it would be better if we test the service tag against an api for this info
					MANUFACTURER="Dell Inc."
					MAKE=$(echo "$MANUFACTURER" | sed -e 's:^Dell$:Dell:' -e 's:^HP$:HP:' -e 's:^VMware$:VMware:')
					MODEL="R620"
					echo "Set MAKE/MODEL based on SVCTAG"
				else
					MANUFACTURER="HP"
					MAKE=$(echo "$MANUFACTURER" | sed -e 's:^Dell$:Dell:' -e 's:^HP$:HP:' -e 's:^VMware$:VMware:')
					MODEL="DL360 G8"
					echo "Set Make/MODEL based on SERIAL"
				fi
			fi
		else
			echo "Error: No System info for Manufacturer"
			EXITCODE=1
			#REFACTOR: lookup model from an api for the manufacturer in this case
		fi
	#else
		#echo "manufacturer not empty"
	fi

}
execute_bit() {

	if [[ -d $BITDIR ]]; then

		cp -R $BITDIR /tmp > /dev/null 2>&1
		yum install -y libusb alsa-lib-devel hdparm > /dev/null 2>&1
		chmod +x /tmp/burnintest/64bit/bit_cmd_line_x64
		cp $BITDIR/configuresystem_logo.png $INSTAPXE_LOGPATH_REMOTE/
		#bit config
		BITCONFIG_FILE="/tmp/burnintest/64bit/cmdline_config.txt"
		sed -i "/LogFilename/ c\LogFilename $INSTAPXE_LOGPATH_REMOTE/" $BITCONFIG_FILE
		sed -i "/LogPrefix/ c\LogPrefix $SVCTAG\_burnintest" $BITCONFIG_FILE
		sed -i "/Format Ascii/ c\Format Certificate" $BITCONFIG_FILE
		sed -i "/#<Notes>/ c\<Notes>" $BITCONFIG_FILE
		sed -i "/#CustomerName Name/ c\CustomerName FBA" $BITCONFIG_FILE
		sed -i "/#TechnicianName Name/ c\TechnicianName INSTAPXE CLUSTER - $LOCATION" $BITCONFIG_FILE
		sed -i "/#MachineType Type/ c\MachineType $MODEL" $BITCONFIG_FILE
		sed -i "/#MachineSerial Serial1234/ c\MachineSerial $SVCTAG" $BITCONFIG_FILE
		sed -i "/#</Notes>/ c\</Notes>" $BITCONFIG_FILE
		sed -i "/AutoStopMinutes 15/ c\AutoStopMinutes 5" $BITCONFIG_FILE
		sed -i "/#TestAllRAWDisks/ c\TestAllRAWDisks" $BITCONFIG_FILE
		sed -i "/#FileSize 1/ c\FileSize 1" $BITCONFIG_FILE
		sed -i "/#TestMode Cyclic/ c\TestMode Cyclic" $BITCONFIG_FILE
		sed -i "/Device \/dev\/sda/ c\#Device \/dev\/sda" $BITCONFIG_FILE

		echo "Executing 5-Minutes Burn-in Test v4.1 - " `timestamp`
		/tmp/burnintest/64bit/bit_cmd_line_x64 > /dev/null 2>&1
		echo "Concluded Burn-in Test - " `timestamp`
		

	fi
}

(

shopt -s expand_aliases > /dev/null 2>&1
alias 'rpm=rpm --ignoresize' > /dev/null 2>&1
mkdir -p /var/cache/yum > /dev/null 2>&1
mount -ttmpfs tmpfs /var/cache/yum > /dev/null 2>&1
echo "diskspacecheck=0" >> /etc/yum.conf > /dev/null 2>&1
export LANG=en_US.UTF-8
#main
cat /DISCLAIMER

echo "Automated System Hardware Scan Initializing.."
echo "Scan started at: " `timestamp` && print_json "STARTED"

clear_eventlogs
#see if make/model is not blank, if it is try to find a match
check_make_model

get_cluster_location

print_sysinfo

#gather dmidecode data
gather_dmidecode
#gather smart data
gather_smart_data

#gather IPMI data
gather_sensor_data hw_scan



case $MAKE in

	*"Dell"*)
		#gather megacli data
		if [[ "$CHASSIS_TYPE" != "Desktop" ]]; then
			gather_mega_data
			reset_idrac
		fi
		;;
	*"HP"*)
		echo "$MAKE"
		
		;;

    	*"VMware"*)

		echo "$MAKE"

        	;;

	*)

		echo "ERROR: No info for manufacturer - $MAKE"
		EXITCODE=1
		;;
esac	
#burnintest
execute_bit
#healthchecks
error_check


case $EXITCODE in


	1)
		echo "Scan exited at: " `timestamp` && print_json "EXITED"
		echo ""
		echo "ERROR: " $EXITCODE
		echo ""
		;;
	*)
		echo "Scan completed at: " `timestamp` && print_json "COMPLETED" 
		elapsed_time
		print_reports_location
		echo "" 
		echo ""
		#shutdowng
		restartg
		;;
esac

) 2>&1 | tee -a $LOGFILE
exit $EXITCODE 
