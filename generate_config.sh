#1/bin/bash

WDS_IP=172.17.1.100

timestamp() {
  date +"%m/%d/%Y-%H:%M:%S" # current time
}


get_os() {
	cat /etc/os-release | grep "^NAME" | cut -d "=" -f 2
}

WORKDIR=$(pwd)

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

        	'"Ubuntu"')

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


get_ip() {
	hostname -I | awk '{print $1}'
}
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

	'"Ubuntu"')
		if ! service_exists gettext-base; then
                       apt-get install gettext-base
                fi
        ;;
	
	*)
		echo `get_os`
		echo "Error: unsupport OS, contact support."
	;;
esac

#set $HOST_IP envvar
#if ! env | grep "HOST_IP" >/dev/null 2>&1; then
	export HOST_IP=`get_ip`
	echo "Generated: HOST_IP envar."
	export WDS_IP
#else
#	echo "HOST_IP already set."
#fi


#set nfs exports
if [ -f $WORKDIR/config/exports.default ]; then
	export HOST_NETWORK=`get_network`
	envsubst < $WORKDIR/config/exports.default > $WORKDIR/config/exports
	echo "Generated: NFS exports file."
fi

#set dsu http config
if [ -f $WORKDIR/config/dsuconfig.xml.default ]; then
        envsubst < $WORKDIR/config/dsuconfig.xml.default > $WORKDIR/nfs/dsu/drm_files/dsuconfig.xml
        echo "Generated: dsuconfig.xml file."
fi
if [ -f $WORKDIR/config/dsuconfig_11.xml.default ]; then
        envsubst < $WORKDIR/config/dsuconfig_11.xml.default > $WORKDIR/nfs/dsu/drm_files/dsuconfig_11.xml
        echo "Generated: dsuconfig_11.xml file."
fi
if [ -f $WORKDIR/src/config/helper_files/dsu_helper.sh ]; then
	insert="NFSMOUNT=\""$HOST_IP":/reports"\"
	sed  -e "s@^NFSMOUNT=.*@$insert@"  $WORKDIR/src/config/helper_files/instapxe_agent.sh  > $WORKDIR/nfs/dsu/drm_files/apply_bundles.sh
        echo "Generated: dsu helper file file."
fi




#set nfs module
modprobe nfs 



