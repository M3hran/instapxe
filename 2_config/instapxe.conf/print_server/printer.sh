docker stop instapxe-printserv
docker rm instapxe-printserv
docker run -dt \
	--privileged \
	-v /var/run/dbus:/var/run/dbus \
        -v /dev/bus/usb:/dev/bus/usb \
        -v /opt/temp/instapxe/print_server:/print_server \
	-p 631:631 \
	--name instapxe-printserv ubuntu 
