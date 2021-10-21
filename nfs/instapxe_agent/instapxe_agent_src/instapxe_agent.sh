#!/bin/bash
printf "\033c"
start_time=$SECONDS
timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}

print_json () {

	if [[ "$1" =~ ^(STARTED)$ ]]; then

                JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"started hardware scan.\"}"

	elif [[ "$1" =~ ^(REBOOT)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"rebooting to apply updates\"}"

        elif [[ "$1" =~ ^(COMPLETED)$ ]]; then
		elapsed=$(( SECONDS - start_time  ))
		atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"

		JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"hw_scan\",\"msg\":\"completed hardware scan\",\"elapsed\":\"$atime\"}"

	elif [[ "$1" =~ ^(EXITED)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"error\",\"stage\":\"hw_scan\",\"msg\":\"exited hardware scan with error\"}"
	       
        fi

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
 	dmidecode > $DSULOGPATHREMOTE/"$SVCTAG"_hardware_inv.txt && sed -i '/dmidecode.*/d' $DSULOGPATHREMOTE/"$SVCTAG"_hardware_inv.txt


}

gather_sensor_data() {
	
	local STATE=$1
        #generat IPMI info report
	echo "Performing health checks..."
        ipmitool sdr type 0x01 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_temp.txt
        ipmitool sdr type 0x02 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_voltage.txt
        ipmitool sdr type 0x03 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_current.txt
        ipmitool sdr type 0x04 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_fan.txt
        ipmitool sdr type 0x05 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_physical_security.txt
        ipmitool sdr type 0x06 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_platform_security.txt
        ipmitool sdr type 0x07 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_processor.txt
        ipmitool sdr type 0x08 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_power_supply.txt
        ipmitool sdr type 0x09 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_power_unit.txt
        ipmitool sdr type 0x0a > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_cooling_device.txt
        ipmitool sdr type 0x0b > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_other.txt
        ipmitool sdr type 0x0c > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_memory.txt
        ipmitool sdr type 0x0d > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_drive_bay.txt
        ipmitool sdr type 0x0e > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_post_memory_resize.txt
        ipmitool sdr type 0x0f > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_firmwares.txt
        ipmitool sdr type 0x10 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_event_logging.txt
        ipmitool sdr type 0x11 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_watchdog1.txt
        ipmitool sdr type 0x12 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_system_event.txt
        ipmitool sdr type 0x13 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_critical_interrupt.txt
        ipmitool sdr type 0x14 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_button.txt
        ipmitool sdr type 0x15 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_board.txt
        ipmitool sdr type 0x16 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_microcontroller.txt
        ipmitool sdr type 0x17 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_add_in_card.txt
        ipmitool sdr type 0x18 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_chassis.txt
        ipmitool sdr type 0x19 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_chip_set.txt
        ipmitool sdr type 0x1a > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_other_fru.txt
        ipmitool sdr type 0x1b > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_cable.txt
        ipmitool sdr type 0x1c > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_terminator.txt
        ipmitool sdr type 0x1d > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_system_boot_init.txt
        ipmitool sdr type 0x1e > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_boot_error.txt
        ipmitool sdr type 0x1f > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_os_boot.txt
        ipmitool sdr type 0x20 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_os_critical_stop.txt
        ipmitool sdr type 0x21 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_slot_connector.txt
        ipmitool sdr type 0x22 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_acpi_power_status.txt
        ipmitool sdr type 0x23 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_watchdog2.txt
        ipmitool sdr type 0x24 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_platform_alert.txt
        ipmitool sdr type 0x25 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_entity_presence.txt
        ipmitool sdr type 0x26 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_monitor_asic.txt
        ipmitool sdr type 0x27 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_lan.txt
        ipmitool sdr type 0x28 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_management_subsystem_health.txt
        ipmitool sdr type 0x29 > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_battery.txt
        ipmitool sdr type 0x2a > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_session_audit.txt
        ipmitool sdr type 0x2b > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_version_change.txt
        ipmitool sdr type 0x2c > "$IPMILOGPATH"/"$STATE"/"$SVCTAG"_fru_state.txt

}

gather_hdd_data(){
	megacli=/opt/MegaRAID/MegaCli/MegaCli64
        echo "Gathering Controller & Disk data.."
        $megacli -ShowSummary -aALL > "$HDDLOGPATH"/"$SVCTAG"_megacli_summary.txt
        $megacli -PDList -aALL > "$HDDLOGPATH"/"$SVCTAG"_physicaldisk_list.txt
        $megacli -LDPDInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_physicaldisk_details.txt
        $megacli -LDInfo -Lall -aALL > "$HDDLOGPATH"/"$SVCTAG"_virtualdrive_info.txt
        $megacli -EncInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_enclosure_info.txt
        $megacli -AdpAllInfo -aALL > "$HDDLOGPATH"/"$SVCTAG"_controller_info.txt
        $megacli -CfgDsply -aALL > "$HDDLOGPATH"/"$SVCTAG"_controller_config_info.txt
        $megacli -AdpBbuCmd -aALL > "$HDDLOGPATH"/"$SVCTAG"_bbu_info.txt
        $megacli -AdpPR -Info -aALL > "$HDDLOGPATH"/"$SVCTAG"_patrolread_state.txt

}


clear_eventlogs(){
	ipmitool sel clear 
}

shutdowng() {

       finalize_reports
       echo "shutting down!"
       sleep 5
       shutdown -h now
}

print_sysinfo() {
	
	echo ""
	echo "    Manufacturer: 		$MANUFACTURER"
	echo "    System Model: 		$MODEL"
	echo "    SVCTAG/Serial: 		$SVCTAG"
	echo ""

}

NFSMOUNT="172.17.1.3:/reports"
WORKDIR="/opt/m3hran"
MANUFACTURER=$(dmidecode -t 1 | awk '/Manufacturer:/ {print $2,$3}')
MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4,$5}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
GENERATION="$(dmidecode -t 1 | awk '/Product Name:/ {print substr($4,3,1)}')"
DSULOGPATHHOST=/usr/libexec/dell_dup
DSULOGPATHREMOTE="$WORKDIR/build/$SVCTAG"
LOGFILE="$DSULOGPATHREMOTE/"$SVCTAG"_hw_scan_log.txt"
IPMILOGPATH="$DSULOGPATHREMOTE/health_checks"
IPMILOGPATH_HWSCAN="$IPMILOGPATH/hw_scan"
JSONPATH="$DSULOGPATHREMOTE/json"
JSONFILE="$JSONPATH/"$SVCTAG"_instapxe.json"

mkdir -p $DSULOGPATHHOST 
mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
mkdir -p $DSULOGPATHREMOTE $IPMILOGPATH $IPMILOGPATH_HWSCAN $JSONPATH> /dev/null 2>&1
touch $LOGFILE $JSONFILE
(

shopt -s expand_aliases > /dev/null 2>&1
alias 'rpm=rpm --ignoresize' > /dev/null 2>&1
mkdir -p /var/cache/yum > /dev/null 2>&1
mount -ttmpfs tmpfs /var/cache/yum > /dev/null 2>&1
echo "diskspacecheck=0" >> /etc/yum.conf > /dev/null 2>&1
export LANG=en_US.UTF-8


echo ""
echo ".__                 __                              "
echo "|__| ____   _______/  |______  _________  ___ ____  "
echo "|  |/    \ /  ___/\   __\__  \ \____ \  \/  // __ \ "
echo "|  |   |  \\___ \  |  |  / __ \|  |_> >    <\  ___/ "
echo "|__|___|  /____  > |__| (____  /   __/__/\_ \\___  >"
echo "        \/     \/            \/|__|        \/    \/ "
echo ""
echo "Copyright (C) Parallax System LLC. All rights reserved."
echo "https://instapxe.com/eula"
echo ""
#echo "Automated System Update Initializing..."
print_sysinfo
echo "Scan started at: " `timestamp` && print_json "STARTED"

#clear old bios logs
clear_eventlogs
#gather IPMI data
gather_sensor_data hw_scan
#gather dmidecode data
gather_dmidecode
#gather megacli data
gather_hdd_data
#gather smart data


MAKE=$(echo "$MANUFACTURER" | sed -e 's:^Dell$:Dell:' -e 's:^HP$:HP:' -e 's:^VMware$:VMware:')

case $MAKE in

	*"Dell"*)

		#echo "DETECTED: 11-th gen "

	        #dsu_preview 1	
                #EXITCODE=$?
		#echo $EXITCODE


		#if [[ $EXITCODE -eq 127 ]]; then
       		
		echo "make identified as: Dell"
		       
		#fi
		
		;;
	*"HP"*)

		#echo "DETECTED: 12-th gen and up"

		#dsu_preview 2
                #EXITCODE=$?
		#echo $EXITCODE

		#if  [[ $EXITCODE -eq 127 ]]; then
		echo "make identified as: HP"		
                #fi

		;;

        *"VMware"*)

                #echo "DETECTED: 12-th gen and up"

                #dsu_preview 2
                #EXITCODE=$?
                #echo $EXITCODE

                #if  [[ $EXITCODE -eq 127 ]]; then
                echo "make identified as: VMware"
                #fi

                ;;

	*)
		
		echo "$MAKE"

#		echo "ERROR: unsupported system!"
#		echo $MODEL
#		echo ""
#		echo "terminating.."
#		exit 1
#		;;
esac	

echo $EXITCODE
case $EXITCODE in


	1)
		print_sysinfo
		echo "Scan exited at: " `timestamp` && print_json "EXITED"
		echo ""
		echo "ERROR: " $EXITCODE
		echo ""
		;;
	*)
		print_sysinfo
		echo "Scan completed at: " `timestamp` && print_json "COMPLETED" 
		elapsed_time	
		echo "" 
		echo ""
		;;
esac

) 2>&1 | tee -a $LOGFILE
exit $EXITCODE 
