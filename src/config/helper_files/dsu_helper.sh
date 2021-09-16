#!/bin/bash
start_time=$SECONDS
timestamp() {
  date +"%m/%d/%Y-%H:%M:%S %p" # current time
}
ntp_config() {

	echo "configuring NTP..."
        yum -y install ntp ntpdate > /dev/null 2>&1
        systemctl start ntpd > /dev/null 2>&1
        ntpdate -u -s 0.centos.pool.ntp.org 1.centos.pool.ntp.org 2.centos.pool.ntp.org > /dev/null 2>&1
        systemctl restart ntpd > /dev/null 2>&1
        hwclock  -w > /dev/null 2>&1
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


NFSMOUNT="172.17.1.3:/reports"
WORKDIR="/opt/m3hran"
MODEL=$(dmidecode -t 1 | awk '/Product Name:/ {print $4}')
SVCTAG=$(dmidecode -t 1 | awk '/Serial Number:/ {print $3}')
GENERATION="$(dmidecode -t 1 | awk '/Product Name:/ {print substr($4,3,1)}')"
LOGFILE="$WORKDIR/$SVCTAG/"$SVCTAG"_update_log.txt"
DSULOGPATHHOST=/usr/libexec/dell_dup
DSULOGPATHREMOTE="$WORKDIR/$SVCTAG"

mkdir -p $DSULOGPATHHOST 

mkdir -p $WORKDIR > /dev/null 2>&1
mount -t nfs -o nolock $NFSMOUNT $WORKDIR > /dev/null 2>&1
touch $LOGFILE
mkdir -p $DSULOGPATHREMOTE > /dev/null 2>&1

if ! service_exists ntpd; then
    ntp_config
fi



(
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
echo ""
echo "Model:   " $MODEL
echo "SVC TAG: " $SVCTAG
echo ""

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

		echo "DETECTED: 11-th gen "
		echo "Update started at: " `timestamp`
		echo ""
       		echo "Starting dsu ..."
	
                dsu \
			-p \
			--non-interactive \
			--ignore-signature \
			--config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml | tee $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
                EXITCODE=$?

		sed -n '/^.*Update Preview/,/^.*NOTE:/w '$DSULOGPATHREMOTE'/'$SVCTAG'_applicable_updates.txt' $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
		rm $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan


		if ! [ "$EXITCODE" == "127" ]; then
			
			echo ""
			echo "##### Starting upgrade #####"
                	dsu \
                        	--non-interactive \
                        	--ignore-signature \
                        	--config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml
			EXITCODE=$?
       		fi
		

		;;

        *)

		echo "DETECTED: 12-th gen and up"
		echo ""
		echo "Update started at: " `timestamp`
		echo "Starting dsu ..."
		


                dsu \
                        -p \
                        --non-interactive \
                        --ignore-signature \
                        --config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml | tee $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
                EXITCODE=$?

                sed -n '/^.*Update Preview/,/^.*NOTE:/w '$DSULOGPATHREMOTE'/'$SVCTAG'_applicable_updates.txt' $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan
                rm $DSULOGPATHREMOTE/"$SVCTAG"_updates.scan

                if ! [ "$EXITCODE" == "127" ]; then

                        echo ""
                        echo "##### Starting upgrade #####"
                        dsu \
                                --non-interactive \
                                --ignore-signature \
                                --config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml
			EXITCODE=$?
                fi


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

flag=0


case $EXITCODE in

	34)

		flag=1
		case $GENERATION in
			1)

                		dsu \
					--inventory \
                        		--config=/opt/dell/toolkit/systems/drm_files/dsuconfig_11.xml \
					--output-inventory-xml=$DSULOGPATHREMOTE/"$SVCTAG"_Update_Summary.xml 

				

				;;
			*)
				
               			 dsu \
                        		--inventory \
                        		--config=/opt/dell/toolkit/systems/drm_files/dsuconfig.xml
				        --output-inventory-xml=$DSULOGPATHREMOTE/"$SVCTAG"_Update_Summary.xml
	
				 ;;
#		 	*)
#				continue
#				;;
		esac

		echo "Update completed at: " `timestamp`
		echo ""
		elapsed_time
		echo ""
		echo "DONE. NO MORE APPLICABLE UPDATES."
		echo ""

		;;
	
	8 | 24 | 25 | 26 )

		echo "Rebooting to apply updates at: " `timestamp`
		echo ""
		elapsed_time
		echo ""
		echo "REBOOTING & APPLYING UPDATES..."
		sleep 3
		reboot
		;;	

	1)
		echo "Updates exited at: " `timestamp`
		echo ""
		elapsed_time
		echo ""
		echo "ERROR: DSU error" $EXITCODE
		echo ""
		;;
	*)
		echo "Updates exited at: " `timestamp`
		echo ""
		elapsed_time
		echo "" 
		echo ""
		echo "DSU exited with status code:" $EXITCODE
		echo ""
		;;
esac





) 2>&1 | tee -a $LOGFILE && dmidecode > $DSULOGPATHREMOTE/"$SVCTAG"_hwinfo.txt && sed -i '/dmidecode.*/d' $DSULOGPATHREMOTE/"$SVCTAG"_hwinfo.txt

if [[ $flag==1 ]]; then

       shutdown -h now
       #continue > /dev/null 2>&1
fi       

exit $EXITCODE 
