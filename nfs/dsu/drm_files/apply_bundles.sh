#!/bin/bash
####################################################################
#
# 2021 instapxe (c) copyright
# https://instapxe.com/eula
# dsu_helper.sh
# maintained by: m3hran
#
####################################################################

printf "\033c"
start_time=$SECONDS
MAC=$(cat /sys/class/net/*/address | head -n 1)
NTPSERVER="172.17.1.3"
NFSMOUNT="172.17.1.3:/reports"
WORKDIR="/opt/m3hran"
MANUFACTURER=$(dmidecode -t 1 | awk '/Manufacturer:/ {print $2,$3}')
MAKE=$(echo "$MANUFACTURER" | sed -e 's:^Dell$:Dell:' -e 's:^HP$:HP:' -e 's:^VMware$:VMware:')
MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4,$5}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
GENERATION="$(dmidecode -t 1 | awk '/Product Name:/ {print substr($4,3,1)}')"
DSULOGPATHHOST=/usr/libexec/dell_dup
DSULOGPATHREMOTE="$WORKDIR/build/$SVCTAG"
LOGFILE="$DSULOGPATHREMOTE/"$SVCTAG"_update_log.txt"
IPMILOGPATH="$DSULOGPATHREMOTE/health_checks"
IPMILOGPATH_PREBUILD="$IPMILOGPATH/pre_build"
IPMILOGPATH_POSTBUILD="$IPMILOGPATH/post_build"
HDDLOGPATH="$DSULOGPATHREMOTE/controller_hdd_info"
JSONPATH="$DSULOGPATHREMOTE/json"
JSONFILE="$JSONPATH/"$SVCTAG"_updates.json"
megacli=/opt/MegaRAID/MegaCli/MegaCli64
racadm=/opt/dell/srvadmin/sbin/racadm

#ntpdate -u $NTPSERVER
mkdir -p $DSULOGPATHHOST
mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
mkdir -p $DSULOGPATHREMOTE $IPMILOGPATH $IPMILOGPATH_PREBUILD $IPMILOGPATH_POSTBUILD $JSONPATH $HDDLOGPATH> /dev/null 2>&1
touch $LOGFILE $JSONFILE

timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}

print_json () {

	if [[ "$1" =~ ^(STARTED)$ ]]; then

                JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"started update\"}"

	elif [[ "$1" =~ ^(REBOOT)$ ]]; then

		elapsed=$(( SECONDS - start_time  ))
                atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"rebooting to apply updates\",\"elapsed\":\"$atime\"}"

        elif [[ "$1" =~ ^(COMPLETED)$ ]]; then

                elapsed=$(( SECONDS - start_time  ))
                atime="$(eval "echo $(date -ud "@$elapsed" +'$((%s/3600/24 )) days %H hr %M min %S sec')")"



 	       JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"completed updates\",\"elapsed\":\"$atime\"}"

	elif [[ "$1" =~ ^(EXITED)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svctag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"mac\":\"$MAC\",\"location\":\"$LOCATION\",\"level\":\"error\",\"stage\":\"Update\",\"msg\":\"exited dsu with error\"}"
	       
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

dsu_inventory() {

	local gen=$1
	if [[ $gen -eq 1 ]]; then

		dsu \
               		--inventory \
               		--config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml \
               		--output-inventory-xml=$DSULOGPATHREMOTE/"$SVCTAG"_update_summary.xml
	fi
        if [[ $gen -eq 2 ]]; then

                dsu \
                        --inventory \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml \
                        --output-inventory-xml=$DSULOGPATHREMOTE/"$SVCTAG"_update_summary.xml
        fi


}

dsu_preview() {

        local gen=$1
	echo ""
        echo "Update started at: " `timestamp` && print_json "STARTED"
        echo "Starting dsu ..."

        if [[ $gen -eq 1 ]]; then

                dsu \
                        -p \
                        --ignore-signature \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml | tee $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan

        fi
        if [[ $gen -eq 2 ]]; then

		dsu \
                        -p \
                        --ignore-signature \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml | tee $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan

        fi

}

dsu_update() {

	local gen=$1
        echo ""
        echo "Update started at: " `timestamp` && print_json "STARTED"
        echo "Starting dsu ..."
	#echo "##### Starting upgrade #####"



        if [[ $gen -eq 1 ]]; then

		dsu \
	                --non-interactive \
                        --ignore-signature \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml
	fi
        if [[ $gen -eq 2 ]]; then

                dsu \
                        --non-interactive \
                        --ignore-signature \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml

	fi
}


finalize_reports() {

	#cleanup update preview summary report
	if [ -f $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan ]; then
		sed -n '/^.*Update Preview/,/^.*NOTE:/w '$DSULOGPATHREMOTE'/'$SVCTAG'_applicable_updates.txt' $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
        	rm $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
	fi

	#cleanup firmware inventory report
	if [ -f $DSULOGPATHREMOTE/"$SVCTAG"_update_summary.xml ]; then
		chmod 644 $DSULOGPATHREMOTE/"$SVCTAG"_update_summary.xml
	fi

	#copy xml file to reports folder
	if [ -f $DSULOGPATHHOST/inv.xml ]; then
		cp $DSULOGPATHHOST/inv.xml $DSULOGPATHREMOTE/"$SVCTAG"_firmware_inv.xml
                chmod 644 $DSULOGPATHREMOTE/"$SVCTAG"_firmware_inv.xml
        fi

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

clear_eventlogs(){
	
	ipmitool sel clear 

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
prebuild() {
	
	echo "Gathering sensors data.."
	ipmitool sel list > $IPMILOGPATH_PREBUILD/"$SVCTAG"_1_bios_errors.txt
	ipmitool sdr list > $IPMILOGPATH_PREBUILD/"$SVCTAG"_2_sensors_health_summary.txt
	clear_eventlogs
	

}
postbuild() {


        echo "Gathering sensors data.."
        ipmitool sel list > $IPMILOGPATH_POSTBUILD/"$SVCTAG"_1_bios_errors.txt
        ipmitool sdr list > $IPMILOGPATH_POSTBUILD/"$SVCTAG"_2_sensors_health_summary.txt
	gather_sensor_data post_build
	gather_hdd_data
	
}
change_bios_mode(){
	local mode=$1
	echo "Setting Boot mode to..$mode"
	$racadm set bios.BiosBootSettings.BootMode $mode
	$racadm jobqueue create BIOS.Setup.1-1

}
shutdowng() {

       finalize_reports
       change_bios_mode Uefi
       echo "shutting down!"
       sleep 5
       shutdown -h now

}
get_cluster_location() {

        interface=$( ifconfig | head -n1 | cut -d ":" -f 1)
        value=$( tcpdump -q -nn -v -i $interface -s 500 -c 1 'ether[20:2]==0x2000' 2> /dev/null |  grep -i "Device-ID\|Port-ID" | cut -d "'" -f 2,4 )
        RACK=$( echo $value | cut -c 2)
        RU=$( echo $value | awk -F '/' '{print $2}' )
        LOCATION="Rack$RACK-U$RU"
}


print_sysinfo() {

        echo ""
        echo "    Manufacturer:                 $MANUFACTURER"
        echo "    System Model:                 $MODEL"
        echo "    SVCTAG/Serial:                $SVCTAG"
        echo "    Cluster Location:             $LOCATION"
        echo ""



}

(
if ! [ -f $IPMILOGPATH_PREBUILD/"$SVCTAG"_1_bios_errors.txt ]; then

	prebuild
fi

cat /DISCLAIMER
echo "Automated System Update Initializing..."
get_cluster_location
print_sysinfo

shopt -s expand_aliases > /dev/null 2>&1
alias 'rpm=rpm --ignoresize' > /dev/null 2>&1
mkdir -p /var/cache/yum > /dev/null 2>&1
mount -ttmpfs tmpfs /var/cache/yum > /dev/null 2>&1
rpm -ivh --nodeps /opt/dell/toolkit/systems/RPMs/rhel7/yumrpms/* > /dev/null 2>&1
echo "diskspacecheck=0" >> /etc/yum.conf > /dev/null 2>&1
#echo "Installing dell-system-update ..."  
if rpm -U --force /opt/dell/toolkit/systems/RPMs/dell-system-update*.rpm > /dev/null 2>&1
then
#  echo "DSU installation successful ..."  
  export LANG=en_US.UTF-8
else
  echo "DSU installation failed."  
  exit 1
fi




case $GENERATION in

	1)

		#echo "DETECTED: 11-th gen "

	        #dsu_preview 1	
                #EXITCODE=$?
		#echo $EXITCODE


		#if [[ $EXITCODE -eq 127 ]]; then
       		
			dsu_update 1
		        EXITCODE=$?
		#fi
		
		;;

        *)

		#echo "DETECTED: 12-th gen and up"

		#dsu_preview 2
                #EXITCODE=$?
		#echo $EXITCODE

		#if  [[ $EXITCODE -eq 127 ]]; then
			
			dsu_update 2
			EXITCODE=$?
                #fi

		;;

#	*)
#
#		echo "ERROR: unsupported system!"
#		echo $MODEL
#		echo ""
#		echo "terminating.."
#		exit 1
#		;;
esac	

echo $EXITCODE
case $EXITCODE in

	34)

#		case $GENERATION in
#			1)
#				dsu_inventory 1
#
#				;;
#			*)
#				
#				dsu_inventory 2
#
#				;;
#		esac

		postbuild
		print_sysinfo
		elapsed_time
		echo ""
		echo "Update completed at: " `timestamp` && print_json "COMPLETED"
		echo "DONE. NO MORE APPLICABLE UPDATES."
		echo ""
		shutdowng

		;;
	
	8 | 24 | 25 | 26 )


		print_sysinfo
		echo "Rebooting to apply updates at: " `timestamp` && print_json "REBOOT"
		elapsed_time
		echo ""
		echo "REBOOTING & APPLYING UPDATES..."
		sleep 3
		shutdown -r now
		;;	

	1)
		print_sysinfo
		echo "Updates exited at: " `timestamp` && print_json "EXITED"
		elapsed_time
		echo ""
		echo "ERROR: DSU error" $EXITCODE
		echo ""
		finalize_reports
		;;
	*)
		#case $GENERATION in
                #        1)
                #                dsu_inventory 1
#
#                                ;;
#                        *)
#
#                                dsu_inventory 2
#
#                                ;;
#		esac


		echo "" 
		echo ""
		if [[ $(tail -n 30 $LOGFILE | grep "Please restart the system") ]]; then
		       	
	                print_sysinfo
	                echo "Rebooting to apply updates at: " `timestamp` && print_json "REBOOT"
        	        elapsed_time
                	echo ""
                	echo "REBOOTING & APPLYING UPDATES..."
                	sleep 3
                	shutdown -r now

	        else	       
	
                	postbuild
                	print_sysinfo
                	elapsed_time
                	echo ""
                	echo "Update completed at: " `timestamp` && print_json "COMPLETED"
                	echo "DONE. NO MORE APPLICABLE UPDATES."
                	echo ""
                	shutdowng

		fi
		;;
esac

) 2>&1 | tee -a $LOGFILE
exit $EXITCODE 
