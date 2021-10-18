#!/bin/bash
start_time=$SECONDS
timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}
ntp_config() {

	echo "Configuring NTP..."
        yum -y install ntp ntpdate >/dev/null 2&>1
        systemctl start ntpd >/dev/null 2&>1
        ntpdate -u -s pool.ntp.org >/dev/null 2&>1
        systemctl restart ntpd >/dev/null 2&>1
        echo "Setting hw clock.."	
        hwclock  -w >/dev/null 2&>1
}

print_json () {

	if [[ "$1" =~ ^(STARTED)$ ]]; then

                JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"started update\"}"

	elif [[ "$1" =~ ^(REBOOT)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"rebooting to apply updates\"}"

        elif [[ "$1" =~ ^(COMPLETED)$ ]]; then

 	       JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"info\",\"stage\":\"Update\",\"msg\":\"completed updates\"}"

	elif [[ "$1" =~ ^(EXITED)$ ]]; then

               JSON_PAYLOAD="{\"time\":\"`timestamp`\",\"manufacturer\":\"Dell\",\"svgtag\":\"$SVCTAG\",\"model\":\"$MODEL\",\"level\":\"error\",\"stage\":\"Update\",\"msg\":\"exited dsu with error\"}"
	       
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
}
shutdowng() {

       finalize_reports
       echo "shutting down!"
       sleep 5
       shutdown -h now

}

print_model_svctag() {
	
	echo ""
	echo "Model:   " $MODEL
	echo "SVC TAG: " $SVCTAG
	echo ""

}

NFSMOUNT="192.168.1.5:/reports"
WORKDIR="/opt/m3hran"
MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
GENERATION="$(dmidecode -t 1 | awk '/Product Name:/ {print substr($4,3,1)}')"
DSULOGPATHHOST=/usr/libexec/dell_dup
DSULOGPATHREMOTE="$WORKDIR/build/$SVCTAG"
LOGFILE="$DSULOGPATHREMOTE/"$SVCTAG"_update_log.txt"
IPMILOGPATH="$DSULOGPATHREMOTE/health_checks"
IPMILOGPATH_PREBUILD="$IPMILOGPATH/pre_build"
IPMILOGPATH_POSTBUILD="$IPMILOGPATH/post_build"
JSONPATH="$DSULOGPATHREMOTE/json"
JSONFILE="$JSONPATH/"$SVCTAG"_updates.json"

mkdir -p $DSULOGPATHHOST 
mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
mkdir -p $DSULOGPATHREMOTE $IPMILOGPATH $IPMILOGPATH_PREBUILD $IPMILOGPATH_POSTBUILD $JSONPATH> /dev/null 2>&1
touch $LOGFILE $JSONFILE
(
if ! service_exists ntpd; then
    ntp_config
fi

if ! [ -f $IPMILOGPATH_PREBUILD/"$SVCTAG"_1_bios_errors.txt ]; then

	prebuild
fi


echo ""
echo ".__                 __                              "
echo "|__| ____   _______/  |______  _________  ___ ____  "
echo "|  |/    \ /  ___/\   __\__  \ \____ \  \/  // __ \ "
echo "|  |   |  \\___ \  |  |  / __ \|  |_> >    <\  ___/ "
echo "|__|___|  /____  > |__| (____  /   __/__/\_ \\___  >"
echo "        \/     \/            \/|__|        \/    \/ "

echo ""
echo "https://instapxe.com"
echo ""
echo "Automated System Update Initializing..."
print_model_svctag

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
		print_model_svctag
		elapsed_time
		echo ""
		echo "Update completed at: " `timestamp` && print_json "COMPLETED"
		echo "DONE. NO MORE APPLICABLE UPDATES."
		echo ""
		shutdowng

		;;
	
	8 | 24 | 25 | 26 )


		print_model_svctag
		echo "Rebooting to apply updates at: " `timestamp` && print_json "REBOOT"
		elapsed_time
		echo ""
		echo "REBOOTING & APPLYING UPDATES..."
		sleep 3
		reboot
		;;	

	1)
		print_model_svctag
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
		postbuild
		print_model_svctag
		echo "Updates completed at: " `timestamp` && print_json "COMPLETED" 
		elapsed_time	
		echo "" 
		echo ""
		shutdowng
		;;
esac

) 2>&1 | tee -a $LOGFILE
exit $EXITCODE 
