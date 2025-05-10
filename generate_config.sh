#!/bin/bash
####################################################################
#
# 2021 instapxe (c) copyright
# https://instapxe.com/eula
# generate_config.sh
# maintained by: m3hran
#
####################################################################



WDS_IP=192.168.1.4
WORKDIR=$(pwd)
CONFIGDIR="$WORKDIR/2_config"
ENVFILE="$CONFIGDIR/default.env"
PENVFILE="$WORKDIR/production.env"

#generates timestamps for logging
timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}

#detect os to install correct packages
get_os() {
	cat /etc/os-release | grep "^NAME" | cut -d "=" -f 2
}


#detect if package/service exists based on os
service_exists() {
	
	local n=$1
	case `get_os` in

        	'"CentOS Linux"')
		

			if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
	        		return 0
			else
	        		return 1
			fi	
        		;;

        	'"Ubuntu"'|'"Debian GNU/Linux"')

                	if dpkg -l | grep $n > /dev/null 2>&1;then
                		return 0

			else
				return 1

                	fi
        		;;

        	*)
                	echo "Error2: unsupport OS, contact support."
			exit 1
        		;;
	esac
}

#get IP address
get_ip() {
	hostname -I | awk '{print $1}'
}
#get NT address
get_network(){
	myip=`get_ip`
	
	ip addr show | grep "inet `get_ip`" | awk '{print $2}'
}


#install envsubst
case `get_os` in

	

	'"CentOS Linux"')
		if ! service_exists gettext; then
    			yum install gettext
		fi
	;;

	 '"Ubuntu"'|'"Debian GNU/Linux"' )
		if ! service_exists gettext-base; then
                       apt-get install gettext-base
                fi
        ;;
	
	*)
		echo `get_os`
		echo "Error: unsupport OS, contact support."
		exit 1
	;;
esac

#set variable in env_file
#if ! env | grep "HOST_IP" >/dev/null 2>&1; then
 	export WDS_IP
 	echo "Generated:  WDS_IP envar"
	export HOST_IP=`get_ip`
	echo "Generated: HOST_IP envar."
	export HOST_NETWORK=`get_network`
	echo "Generated: HOST_NETWORK envar"
	export API=http://$HOST_IP:9010/api
	echo "Generated: API envar"

      
	envsubst < $ENVFILE > $PENVFILE


#else
#	echo "HOST_IP already set."
#fi

#set tftp config
if [ -f $CONFIGDIR/instapxe-tftp.cfg/dnsmasq.default ]; then
	envsubst < $CONFIGDIR/instapxe-tftp.cfg/dnsmasq.default > $CONFIGDIR/instapxe-tftp.cfg/dnsmasq.conf
	echo "Generated: dnsmasq config."
else
	echo "Error: dnsmasq config not found"
fi
#set nfs exports
if [ -f $CONFIGDIR/nfs.cfg/exports.default ]; then
	envsubst < $CONFIGDIR/nfs.cfg/exports.default > $WORKDIR/nfs/exports
	echo "Generated: NFS exports file."
else
	echo "Error: NFS config not found"
fi


#set dsu http config
if [ -f $CONFIGDIR/dsu.cfg/dsuconfig.xml.default ]; then
        envsubst < $CONFIGDIR/dsu.cfg/dsuconfig.xml.default > $WORKDIR/nfs/dsu/drm_files/dsuconfig.xml
        echo "Generated: dsuconfig.xml file."
else
        echo "Error: DSU config not found"

fi

#set dsu_11 config
if [ -f $CONFIGDIR/dsu.cfg/dsuconfig_11.xml.default ]; then
        envsubst < $CONFIGDIR/dsu.cfg/dsuconfig_11.xml.default > $WORKDIR/nfs/dsu/drm_files/dsuconfig_11.xml
        echo "Generated: dsuconfig_11.xml file."
else
        echo "Error: DSU_11 config not found"


fi

#set dsu_helper script
if [ -f $CONFIGDIR/dsu.cfg/dsu_helper.sh.default ]; then
	insert="NFSMOUNT=\""$HOST_IP":/reports"\"
 	insertntp="NTPSERVER=\""$HOST_IP\"
	insertapi="API=\""$API"/device/"\"
	sed  -e "s@^NFSMOUNT=.*@$insert@" -e "s@^NTPSERVER=.*@$insertntp@" -e "s@^API=.*@$insertapi@"  $CONFIGDIR/dsu.cfg/dsu_helper.sh.default  > $WORKDIR/nfs/dsu/drm_files/apply_bundles.sh
        echo "Generated: dsu helper script."
else
        echo "Error: DSU helper script not found"
fi
#set instapxe_agent config
if [ -f $CONFIGDIR/instapxe_agent.cfg/instapxe_agent.sh.default ]; then
        insert="NFSMOUNT=\""$HOST_IP":/reports"\"
	insertntp="NTPSERVER=\""$HOST_IP\"	
	insertapi="API=\""$API"/device/"\"
	sed  -e "s@^NFSMOUNT=.*@$insert@" -e "s@^NTPSERVER=.*@$insertntp@" -e "s@^API=.*@$insertapi@" $CONFIGDIR/instapxe_agent.cfg/instapxe_agent.sh.default  > $WORKDIR/nfs/instapxe_agent/instapxe_agent_src/instapxe_agent.sh
        echo "Generated: instapxe_agent file."
else
        echo "Error: instaPXE agent script not found"

fi

export $(cat $PENVFILE | xargs)
INSTALLDIR="./2_config/instapxe.conf"
PATHS="$INSTALLDIR/bios $INSTALLDIR/efi32 $INSTALLDIR/efi64"
for i in $PATHS
do
        #check for user mounted volume
        
	if [ -d ./tftp ]; then
			cp -R ./tftp/* $i/boot 
			echo "Boot ROMs loaded."
	fi
	#generate default menu
	if [[ $i == $INSTALLDIR/bios ]]; then
		
			#ln -s $i/pxelinux.cfg /instapxe.conf/bios
		envsubst < ./2_config/menufiles/instapxe.menu > $i/pxelinux.cfg/default
		echo "BIOS menus created."
	fi
	#generate submenus

        if [[ $i == $INSTALLDIR/bios ]]; then

                        #ln -s $i/pxelinux.cfg /instapxe.conf/bios
                envsubst < ./2_config/menufiles/ubuntu.menu > $i/pxelinux.cfg/ubuntu.menu
                echo "UBUNTU submenus created."
        fi
        if [[ $i == $INSTALLDIR/bios ]]; then

                        #ln -s $i/pxelinux.cfg /instapxe.conf/bios
                envsubst < ./2_config/menufiles/centos.menu > $i/pxelinux.cfg/centos.menu
                echo "CENTOS submenus created."
        fi
	if [[ $i == $INSTALLDIR/efi32 ]]; then
			
			#ln -s $i/pxelinux.cfg /instapxe.conf/uefi32
		envsubst < ./2_config/menufiles/instapxe.menu64 > $i/pxelinux.cfg/default
		echo "UEFI32 menus created."

	fi
	if [[ $i == $INSTALLDIR/efi64 ]]; then
			
			#ln -s $i/pxelinux.cfg /instapxe.conf/uefi64
		envsubst < ./2_config/menufiles/instapxe.menu64 > $i/pxelinux.cfg/default
		echo "UEFI64 menus created."

	fi

	if ! [ $(head -5 $i/pxelinux.cfg/default | grep -qxF 'MENU INCLUDE pxelinux.cfg/instapxe.conf)') ]; then
                cp $i/pxelinux.cfg/default /tmp/tmpdefault
                sed -i '/.*menu.c32.*/a MENU INCLUDE pxelinux.cfg\/instapxe.conf' /tmp/tmpdefault
                cp /tmp/tmpdefault $i/pxelinux.cfg/default
                rm /tmp/tmpdefault
        fi
        
done


#set nfsd module
modprobe nfsd
echo nfsd > /etc/modules-load.d/nfsd.conf
echo nfs > /etc/modules-load.d/nfs.conf
echo "Added: nfs kernel modules."

#disable host rpc bind 111,2049
systemctl stop nfs-server
systemctl disable nfs-server
systemctl disable rpcbind.target
systemctl disable rpcbind.socket
systemctl disable rpcbind.service
systemctl stop rpcbind.target
systemctl stop rpcbind.socket
systemctl stop rpcbind.service
