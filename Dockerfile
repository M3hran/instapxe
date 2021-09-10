FROM alpine:3.12.0
##########################################################################
# author: m3hran
# image name: instapxe/instapxe
#
# copyright (c) instaPXE -- Parallax System LLC 2021
# LICENSE AGREEMENT: https://instapxe.com/eula
#
# 
#      
#########################################################################
ADD syslinux-6.04-pre2 /var/opt/instapxe

# Add safe defaults that can be overriden easily.
ADD instapxe_bios.cfg /var/opt/instapxe/bios/pxelinux.cfg/
ADD instapxe_uefi32.cfg /var/opt/instapxe/efi32/pxelinux.cfg/
ADD instapxe_uefi64.cfg /var/opt/instapxe/efi64/pxelinux.cfg/

# Support clients that use backslash instead of forward slash.
#COPY mapfile /instapxe/

# Do not track further change to /instapxe.
VOLUME /var/opt/instapxe

# http://forum.alpinelinux.org/apk/main/x86_64/tftp-hpa
RUN apk add --no-cache tftp-hpa

RUN adduser -D instapxe

COPY src/init /var/opt/instapxe/init
COPY src/start /usr/sbin/start
ENTRYPOINT ["/usr/sbin/start"]

#CMD ["-L", "--verbose", "-m", "/instapxe/mapfile", "-u", "tftp", "--secure", "/instapxe"]
CMD ["-L", "--verbose", "-u", "instapxe", "--secure", "/var/opt/instapxe"]
